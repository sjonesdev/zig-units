const std = @import("std");
const Unitless = @import("unit.zig").Unitless;
const math = std.math;
const fmt = std.fmt;

inline fn isNumType(T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

inline fn isNumber(val: anytype) bool {
    return isNumType(@TypeOf(val));
}

// could try to implement kinds where different quantities of
// the same units/dimension are not compatible
// this could also solve the case of needing dynamic dimensions
// since if you could make any kind of unit you don't need different dimensions
// or we could give the kinds to the units themselves
// mp-units created a concept of named unit on top of kind_of<dimension>
pub fn Quantity(UnitIn: type, ValueTypeIn: type) type {
    return struct {
        const This = @This();
        const ValueType = ValueTypeIn;
        pub const Unit = UnitIn;

        /// A value of type `Self.ValueType` and unit `Self.Unit`.
        /// It is recommended to use `in()` instead of accessing this
        /// value directly for clarity.
        value: ValueType,

        inline fn baseValue(self: This) @TypeOf(self.value, 0.0) {
            return (self.value - This.Unit.offset) / This.Unit.multiplier;
        }

        /// Converts this quantity's value to OtherUnit and returns the resulting Quantity
        pub inline fn in(
            self: This,
            OtherUnit: type,
        ) if (This.Unit.equals(OtherUnit)) ValueType else @TypeOf(self.value, 0.0) {
            if (This.Unit.equals(OtherUnit)) return self.value;
            const base_value = self.baseValue();
            return @mulAdd(
                @TypeOf(base_value, 0.0),
                base_value,
                OtherUnit.multiplier,
                OtherUnit.offset,
            );
        }

        /// Converts this quantity's value to OtherUnit and returns the resulting value
        pub inline fn to(
            self: This,
            OtherUnit: type,
        ) Quantity(
            OtherUnit,
            if (This.Unit.equals(OtherUnit)) ValueType else @TypeOf(self.value, 0.0),
        ) {
            return .{ .value = self.in(OtherUnit) };
        }

        /// Converts this quantity's value to a value of type T and returns
        /// the resulting Quantity
        ///
        /// This will allow conversion from integers to floats as well, but
        /// not from floats to integers
        pub inline fn as(self: This, T: type) Quantity(This.Unit, T) {
            if (@typeInfo(ValueType) == .int) {
                return .{ .value = @as(T, @floatFromInt(self.value)) };
            }
            return .{ .value = @as(T, self.value) };
        }

        // TODO support integer quantities by automatically calling @floatFromInt where appropriate
        pub inline fn plus(
            self: This,
            rhs: anytype,
        ) Quantity(
            This.Unit,
            @TypeOf(
                self.value,
                if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const Rhs = @TypeOf(rhs);
            // TODO handle pointers to quantities (either by literally handling them or providing a custom error message)
            if (!(This.Unit.Dimension == Rhs.Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            const right_val = if (This.Unit.equals(Rhs.Unit)) rhs.value else rhs.in(This.Unit);
            return .{ .value = self.value + right_val };
        }

        pub inline fn minus(
            self: This,
            rhs: anytype,
        ) Quantity(
            This.Unit,
            @TypeOf(
                self.value,
                if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const Rhs = @TypeOf(rhs);
            if (!(This.Unit.Dimension == Rhs.Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            const right_val = if (This.Unit.multiplier == Rhs.Unit.multiplier and
                This.Unit.offset == Rhs.Unit.offset) rhs.value else rhs.in(This.Unit);
            return .{ .value = self.value - right_val };
        }

        /// Multiplies two quantities. Note that normal multiplication rules apply here.
        pub inline fn times(
            self: This,
            rhs: anytype,
        ) Quantity(
            This.Unit.Of(@TypeOf(rhs).Unit),
            @TypeOf(
                self.value,
                if (isNumType(@TypeOf(rhs))) rhs else if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const right_val = if (isNumber(rhs)) blk: {
                break :blk rhs;
            } else rhs.in(This.Unit);
            return .{ .value = self.value * right_val };
        }

        /// Divides two quantities. Note that normal division rules apply here,
        /// meaning if you divide two integer quantities, integer division will
        /// be performed. Additionally, ambiguous coercions will error out.
        pub inline fn div(
            self: This,
            rhs: anytype,
        ) Quantity(
            This.Unit.Per(@TypeOf(rhs).Unit),
            @TypeOf(
                self.value,
                if (isNumType(@TypeOf(rhs))) rhs else if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const right_val = if (isNumber(rhs)) blk: {
                break :blk rhs;
            } else rhs.in(This.Unit);
            return .{ .value = self.value / right_val };
        }

        pub inline fn eq(self: This, rhs: anytype) bool {
            return self.value == rhs.in(This.Unit);
        }

        /// Recommended for comparing small numbers close to 0. See
        /// `std.math.approxEqAbs` for more info.
        pub inline fn approxEqAbs(self: This, rhs: anytype, tolerance: anytype) bool {
            return math.approxEqAbs(
                @TypeOf(self.value, rhs.in(This.Unit), tolerance),
                self.value,
                rhs.in(This.Unit),
                tolerance,
            );
        }

        /// Recommended for comparing numbers not close to 0. See
        /// `std.math.approxEqRel` for more info.
        pub inline fn approxEqRel(self: This, rhs: anytype, tolerance: anytype) bool {
            return math.approxEqRel(
                @TypeOf(self.value, rhs.in(This.Unit), tolerance),
                self.value,
                rhs.in(This.Unit),
                tolerance,
            );
        }

        pub inline fn gt(self: This, rhs: anytype) bool {
            return self.value > rhs.in(This.Unit);
        }

        pub inline fn lt(self: This, rhs: anytype) bool {
            return self.value < rhs.in(This.Unit);
        }

        pub inline fn gte(self: This, rhs: anytype) bool {
            return self.value >= rhs.in(This.Unit);
        }

        pub inline fn lte(self: This, rhs: anytype) bool {
            return self.value <= rhs.in(This.Unit);
        }

        /// see `@abs`
        pub inline fn abs(self: This) Quantity(
            This.Unit,
            This.ValueType,
        ) {
            return .{ .value = @abs(self.value) };
        }

        /// Only works for quantities with underlying value type
        /// `f32` or `f64`. See `std.math.pow` for more info.
        pub inline fn pow(self: This, power: ValueType) Quantity(
            This.Unit.Pow(power),
            ValueType,
        ) {
            return .{ .value = math.pow(ValueType, self.value, power) };
        }

        /// 1 / Quantity
        pub inline fn inv(self: This) Quantity(This.Unit.Inv(), ValueType) {
            return Unitless.of(1).div(self);
        }

        /// for comptime
        pub fn str(self: This, PrintInUnit: type) []const u8 {
            comptime {
                return fmt.comptimePrint("{d}{s}", .{ self.in(PrintInUnit), PrintInUnit.abbreviation });
            }
        }

        /// for comptime
        pub fn fullStr(self: This, PrintInUnit: type) []const u8 {
            comptime {
                return fmt.comptimePrint("{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
            }
        }

        // TODO print in scientific notation if possible upon no space left error (or maybe try to detect this with heuristic)
        /// See `std.fmt.bufPrint`
        pub fn bufStr(self: This, PrintInUnit: type, buf: []u8) fmt.BufPrintError![]const u8 {
            return fmt.bufPrint(buf, "{d}{s}", .{ self.in(PrintInUnit), PrintInUnit.abbreviation });
        }

        /// See `std.fmt.bufPrint`
        pub fn bufFullStr(self: This, PrintInUnit: type, buf: []u8) fmt.BufPrintError![]const u8 {
            return fmt.bufPrint(buf, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }

        /// See `std.fmt.allocPrint`
        pub fn allocStr(self: This, PrintInUnit: type, alloc: std.mem.Allocator) fmt.AllocPrintError![]const u8 {
            return fmt.allocPrint(alloc, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }

        /// See `std.fmt.allocPrint`
        pub fn allocFullStr(self: This, PrintInUnit: type, alloc: std.mem.Allocator) fmt.AllocPrintError![]const u8 {
            return fmt.allocPrint(alloc, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }
    };
}

// Make a quantity of the unit with the type of value
// passed as the underlying type. The value is stored as
// passed (i.e. in this unit).
pub inline fn quantity(Unit: type, value: anytype) Quantity(Unit, @TypeOf(value)) {
    return .{ .value = value };
}
