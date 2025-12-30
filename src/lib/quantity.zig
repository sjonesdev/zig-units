const std = @import("std");
const fmt = std.fmt;
const math = std.math;
const util = @import("util.zig");
const u = @import("unit.zig");

/// would be more ideal if we didn't have to parameterize this, but I don't think that's possible
///
/// how can we allow function parameter that for example look like (var: is_kind<length>)
///
/// maybe to start with we can have a return type builder that enforces contracts
///
/// e.g. fn doOp(num: anytype): contract.params(of_kind(length)).returns(of_kind(length))
pub fn Quantity(QuantitySpecIn: type, ValueType: type) type {
    return struct {
        const This = @This();
        pub const QuantitySpec = QuantitySpecIn;

        Unit: type,

        /// A value of the provided type and unit.
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

        /// OLD
        /// Converts this quantity's value to a value of type T and returns
        /// the resulting Quantity
        ///
        /// This will allow conversion from integers to floats as well, but
        /// not from floats to integers
        ///
        /// NEW
        /// Allows conversion of the internal value type or the quantity spec,
        /// following standard casting conventions for changing the value type,
        /// and following ISQ semantics for casting the quantity spec.
        ///
        /// This can only be used to cast down up a quantity spec tree (i.e. cast to
        /// a more generalized quantity spec), to cast down/narrow the quantity spec,
        /// you must use `Quantity(...).resolveToKind(kind: QuantityKind)`
        ///
        /// To convert to a kind from a different hierarchy, you must perform this manually
        pub inline fn as(self: This, T: type) Quantity(This.QuantitySpec, T) {
            const typeInfo = @typeInfo(T);
            switch (typeInfo) {
                .comptime_float, .comptime_int, .float, .int => {},
                .type => {},
            }
            if (@typeInfo(ValueType) == .int) {
                return .{ .value = @as(T, @floatFromInt(self.value)) };
            }
            return .{ .value = @as(T, self.value) };
        }

        /// Cast this quantity down the quantity kind hierarchy, further specifying
        /// its kind
        ///
        /// This function only works for traversing down the kind hierarchy, not up
        ///
        /// e.g.
        pub inline fn resolveToKind(self: This, ToQuantitySpec: type) Quantity(ToQuantitySpec, ValueType) {
            // TODO validate
            return Quantity(ToQuantitySpec, ValueType){ .value = self.value };
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
                if (util.isNumberType(@TypeOf(rhs))) rhs else if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const right_val = if (util.isNumber(rhs)) blk: {
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
                if (util.isNumberType(@TypeOf(rhs))) rhs else if (This.Unit.equals(@TypeOf(rhs).Unit)) rhs.value else rhs.in(This.Unit),
            ),
        ) {
            const right_val = if (util.isNumber(rhs)) blk: {
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

        /// 1 / Quantity; inverse; reciprocal
        pub inline fn inv(self: This) Quantity(This.Unit.Inv(), ValueType) {
            return u.One.of(1).div(self);
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

// fn funcWithQuantityTypeSig(val: Quantity())

test "Quantites work" {}
