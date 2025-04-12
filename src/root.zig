const std = @import("std");
const testing = std.testing;

inline fn isNumType(T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

inline fn isNumber(val: anytype) bool {
    return isNumType(@TypeOf(val));
}

/// unicode character symbol
const DimensionComponent = enum(u21) {
    time = 'T',
    length = 'L',
    mass = 'M',
    current = 'I',
    temp = 'Θ',
    amount = 'N',
    luminosity = 'J',
    angle = 'R',
    none = '0',
};

fn Dimension(
    t_in: comptime_int,
    l_in: comptime_int,
    m_in: comptime_int,
    i_in: comptime_int,
    d_in: comptime_int,
    n_in: comptime_int,
    j_in: comptime_int,
    r_in: comptime_int,
) type {
    return struct {
        const Self = @This();
        const t = t_in;
        const l = l_in;
        const m = m_in;
        const i = i_in;
        const d = d_in;
        const n = n_in;
        const j = j_in;
        const r = r_in;

        pub fn MultipliedBy(Dim: type) type {
            return Dimension(
                t + Dim.t,
                l + Dim.l,
                m + Dim.m,
                i + Dim.i,
                d + Dim.d,
                n + Dim.n,
                j + Dim.j,
                r + Dim.r,
            );
        }

        pub fn DividedBy(Dim: type) type {
            return Dimension(
                t - Dim.t,
                l - Dim.l,
                m - Dim.m,
                i - Dim.i,
                d - Dim.d,
                n - Dim.n,
                j - Dim.j,
                r - Dim.r,
            );
        }

        pub inline fn equals(Dim: type) bool {
            return t == Dim.t and
                l == Dim.l and
                m == Dim.m and
                i == Dim.i and
                d == Dim.d and
                n == Dim.n and
                j == Dim.j and
                r == Dim.r;
        }

        pub inline fn isBase() bool {
            const sum = @abs(t) + @abs(l) + @abs(m) + @abs(i) + @abs(d) + @abs(n) + @abs(j) + @abs(r);
            return sum == 1 or sum == 0;
        }

        pub fn str() []const u8 {
            return std.fmt.comptimePrint(
                "{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d}",
                .{
                    @intFromEnum(DimensionComponent.time),       t,
                    @intFromEnum(DimensionComponent.length),     l,
                    @intFromEnum(DimensionComponent.mass),       m,
                    @intFromEnum(DimensionComponent.current),    i,
                    @intFromEnum(DimensionComponent.temp),       d,
                    @intFromEnum(DimensionComponent.amount),     n,
                    @intFromEnum(DimensionComponent.luminosity), j,
                    @intFromEnum(DimensionComponent.angle),      r,
                },
            );
        }
    };
}

/// Used to create a dimension orthogonal to all other existing base dimensions.
/// This can be used to add custom dimensions (e.g. dollars), or encode semantics
/// into an existing dimension to treat them as orthogonal.
fn BaseDimension(comptime dim: DimensionComponent) type {
    const Dim = Dimension(
        if (dim == .time) 1 else 0,
        if (dim == .length) 1 else 0,
        if (dim == .mass) 1 else 0,
        if (dim == .current) 1 else 0,
        if (dim == .temp) 1 else 0,
        if (dim == .amount) 1 else 0,
        if (dim == .luminosity) 1 else 0,
        if (dim == .angle) 1 else 0,
    );
    const dims = Dim.t + Dim.l + Dim.m + Dim.i + Dim.d + Dim.n + Dim.j;
    comptime std.debug.assert(dims != 1 or dims != 0);
    return Dim;
}

// Base Dimensions
pub const Time = BaseDimension(.time);
pub const Length = BaseDimension(.length);
pub const Mass = BaseDimension(.mass);
pub const Current = BaseDimension(.current);
pub const Temperature = BaseDimension(.temp);
pub const Amount = BaseDimension(.amount);
pub const Luminosity = BaseDimension(.luminosity);
pub const Angle = BaseDimension(.angle);
pub const Dimensionless = BaseDimension(.none);

// Compound Dimensions
pub const Velocity = Length.DividedBy(Time);
pub const Acceleration = Velocity.DividedBy(Time);
pub const Jerk = Acceleration.DividedBy(Time);
pub const Snap = Jerk.DividedBy(Time);
pub const Crackle = Snap.DividedBy(Time);
pub const Pop = Crackle.DividedBy(Time);
pub const Goldfish = Pop.DividedBy(Time);
pub const Force = Mass.MultipliedBy(Acceleration);
pub const Area = Length.MultipliedBy(Length);
pub const Pressure = Force.DividedBy(Area);
pub const Energy = Force.MultipliedBy(Length);
pub const Power = Energy.DividedBy(Time);
pub const Charge = Current.MultipliedBy(Time);
pub const Voltage = Power.DividedBy(Current);
pub const Capacitance = Charge.DividedBy(Voltage);
pub const Frequency = Dimensionless.DividedBy(Seconds);
pub const Torque = Energy;
pub const Momentum = Torque.DividedBy(Time);
pub const Impulse = Momentum;
pub const MomentOfInertia = Torque.MultipliedBy(Length);
pub const Resistance = Voltage.DividedBy(Current);

/// DimensionIn - dimension of unit
/// name_in - display name of unit
/// abbreviation_in - display abbreviation of unit
/// multiplier_in - the value the unit must be multiplied by to convert to it's base unit
/// offset_in - the value that must be added to the unit (after being multiplied) to convert to it's base unit
fn Unit(DimensionIn: type, name_in: []const u8, abbreviation_in: []const u8, multiplier_in: comptime_float, offset_in: comptime_float) type {
    return struct {
        const Self = @This();
        const Dimension = DimensionIn;
        pub const name = name_in;
        pub const abbreviation = abbreviation_in;
        const multiplier: comptime_float = multiplier_in;
        const offset: comptime_float = offset_in;

        pub fn ScaledTo(unit_name: []const u8, unit_abbreviation: []const u8, scale_factor: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
                unit_abbreviation,
                scale_factor * multiplier,
                offset * multiplier,
            );
        }

        pub fn OffsetTo(unit_name: []const u8, unit_abbreviation: []const u8, offset_value: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
                unit_abbreviation,
                multiplier,
                offset_value,
            );
        }

        /// Unit * RightUnit
        pub fn Of(RightUnit: type) type { // maybe rename to Dot?
            return DerivedUnit(
                @This(),
                RightUnit,
                .multiply,
            );
        }

        /// Unit / RightUnit
        pub fn Per(RightUnit: type) type {
            return DerivedUnit(
                @This(),
                RightUnit,
                .divide,
            );
        }

        /// Inverse, Unit^(-1)
        pub fn Inv() type {
            return Unitless.Per(Self);
        }

        /// Unit^(power), power > 0
        pub fn ToThe(power: comptime_int) type {
            if (power <= 0) {
                @compileError("ToThe only supports integers >0");
            }
            var Result = Self;
            for (1..power) |_| {
                Result = Result.Of(Self);
            }
            return Result;
        }

        /// Unit^(-power), power > 0
        pub fn Root(power: comptime_int) type {
            if (power <= 0) {
                @compileError("Root only supports integers >0");
            }
            var Result = Inv();
            for (1..power) |_| {
                Result = Result.Per(Self);
            }
            return Result;
        }

        /// Unit^(power)
        pub fn Pow(power: comptime_int) type {
            if (power == 0) {
                return Unitless;
            } else if (power < 0) {
                return Root(@abs(power));
            } else {
                return ToThe(power);
            }
        }

        pub fn Named(new_name: []const u8, new_abbreviation: []const u8) type {
            return Unit(
                Self.Dimension,
                new_name,
                new_abbreviation,
                multiplier,
                offset,
            );
        }

        pub fn Abbreviated(new_abbreviation: []const u8) type {
            return Unit(
                Self.Dimension,
                name,
                new_abbreviation,
                multiplier,
                offset,
            );
        }

        pub inline fn equals(OtherUnit: type) bool {
            return Self.multiplier == OtherUnit.multiplier and Self.offset == OtherUnit.offset;
        }

        pub inline fn of(
            value: anytype,
        ) Quantity(
            Self,
            if (@typeInfo(@TypeOf(value)) == .comptime_int) comptime_float else @TypeOf(value),
        ) {
            return .{ .value = value };
        }
    };
}

const UnitCombinationOperation = enum { multiply, divide };
fn DerivedUnit(
    LeftHandUnit: type,
    RightHandUnit: type,
    operation: UnitCombinationOperation,
) type {
    if (LeftHandUnit.offset != 0 or RightHandUnit.offset != 0) {
        @compileError("Deriving from an offset unit is not allowed");
    }
    const Dim: type, const name: []const u8, const mult: comptime_float = switch (operation) {
        .multiply => .{
            LeftHandUnit.Dimension.MultipliedBy(RightHandUnit.Dimension),
            LeftHandUnit.name ++ "*" ++ RightHandUnit.name,
            LeftHandUnit.multiplier * RightHandUnit.multiplier,
        },
        .divide => .{
            LeftHandUnit.Dimension.DividedBy(RightHandUnit.Dimension),
            LeftHandUnit.name ++
                "/" ++
                if (RightHandUnit.Dimension.isBase()) RightHandUnit.name else "(" ++ RightHandUnit.name ++ ")",
            LeftHandUnit.multiplier / RightHandUnit.multiplier,
        },
    };

    return Unit(
        Dim,
        name,
        "", // TODO
        mult,
        0,
    );
}

pub fn BaseUnit(DimensionIn: type, name_in: []const u8, abbreviation_in: []const u8) type {
    return Unit(DimensionIn, name_in, abbreviation_in, 1, 0);
}
inline fn RoughlySameSizedFloatAsInt(int_info: std.builtin.Type.Int) type {
    if (int_info.bits <= 16) {
        return f16;
    } else if (int_info.bits <= 32) {
        return f32;
    } else if (int_info.bits <= 64) {
        return f64;
    } else if (int_info.bits <= 80) {
        return f80;
    }
    return f128;
}
inline fn ResolveValueType(LeftType: type, RightType: type) type {
    const linfo = @typeInfo(LeftType);
    const rinfo = @typeInfo(RightType);
    const left_val: LeftType = 0;
    const right_val: RightType = 0;

    if (linfo == .int and rinfo == .comptime_float) {
        const left_coerced = @as(
            RoughlySameSizedFloatAsInt(linfo.int),
            @floatFromInt(left_val),
        );
        return @TypeOf(left_coerced, right_val);
    } else if (linfo == .comptime_float and rinfo == .int) {
        const right_coerced = @as(
            RoughlySameSizedFloatAsInt(rinfo.int),
            @floatFromInt(right_val),
        );
        return @TypeOf(left_val, right_coerced);
    }
    return @TypeOf(left_val, right_val);
}

const Op = enum {
    add,
    sub,
    mul,
    div,
};
inline fn arithmetic(T: type, l: anytype, r: anytype, op: Op) T {
    return switch (op) {
        .add => l + r,
        .sub => l - r,
        .mul => l * r,
        .div => l / r,
    };
}
inline fn coerciveArithmetic(left_val: anytype, right_val: anytype, operation: Op) ResolveValueType(@TypeOf(left_val), @TypeOf(right_val)) {
    const ResultType = ResolveValueType(@TypeOf(left_val), @TypeOf(right_val));
    const LeftType = @TypeOf(left_val);
    const RightType = @TypeOf(right_val);
    const linfo = @typeInfo(LeftType);
    const rinfo = @typeInfo(RightType);
    if (linfo == .int and (rinfo == .comptime_float or rinfo == .float)) {
        return arithmetic(
            ResultType,
            @as(
                RoughlySameSizedFloatAsInt(linfo.int),
                @floatFromInt(left_val),
            ),
            right_val,
            operation,
        );
    } else if ((linfo == .comptime_float or linfo == .float) and rinfo == .int) {
        return arithmetic(
            ResultType,
            left_val,
            @as(
                RoughlySameSizedFloatAsInt(rinfo.int),
                @floatFromInt(right_val),
            ),
            operation,
        );
    } else return arithmetic(
        ResultType,
        left_val,
        right_val,
        operation,
    );
}

fn Quantity(UnitIn: type, ValueTypeIn: type) type {
    return struct {
        const Self = @This();
        const Unit = UnitIn;
        const ValueType = ValueTypeIn;

        value: ValueType,

        inline fn baseValue(self: Self) ResolveValueType(ValueType, comptime_float) {
            // check if this is base unit
            // TODO @mulAdd?
            return coerciveArithmetic(
                self.value,
                Self.Unit.multiplier,
                .mul,
            ) + Self.Unit.offset;
        }

        /// Converts this quantity's value to OtherUnit and returns the resulting Quantity
        inline fn in(self: Self, OtherUnit: type) if (Self.Unit.equals(OtherUnit)) ValueType else ResolveValueType(
            ValueType,
            @TypeOf(self.baseValue()),
        ) {
            if (Self.Unit.equals(OtherUnit)) return self.value;
            const base_value = self.baseValue();
            return (base_value - OtherUnit.offset) / OtherUnit.multiplier;
        }

        /// Converts this quantity's value to OtherUnit and returns the resulting value
        pub inline fn to(self: Self, OtherUnit: type) Quantity(
            OtherUnit,
            ResolveValueType(
                ValueType,
                @TypeOf(self.baseValue()),
            ),
        ) {
            return .{ .value = self.in(OtherUnit) };
        }

        /// Converts this quantity's value to a value of type T and returns
        /// the resulting Quantity
        ///
        /// This will allow conversion from integers to floats as well, but
        /// not from floats to integers
        pub inline fn as(self: Self, T: type) Quantity(Self.Unit, T) {
            if (@typeInfo(ValueType) == .int) {
                return .{ .value = @as(T, @floatFromInt(self.value)) };
            }
            return .{ .value = @as(T, self.value) };
        }

        // TODO support integer quantities by automatically calling @floatFromInt where appropriate
        pub inline fn plus(
            self: Self,
            rhs: anytype,
        ) Quantity(
            Self.Unit,
            ResolveValueType(
                ValueType,
                @TypeOf(rhs.in(Self.Unit)),
            ),
        ) {
            const Rhs = @TypeOf(rhs);
            // TODO handle pointers to quantities (either by literally handling them or providing a custom error message)
            if (!Self.Unit.Dimension.equals(Rhs.Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            const right_val = if (Self.Unit.equals(Rhs.Unit)) rhs.value else rhs.in(Self.Unit);
            return .{ .value = coerciveArithmetic(
                self.value,
                right_val,
                .add,
            ) };
        }

        pub inline fn minus(
            self: Self,
            rhs: anytype,
        ) Quantity(Self.Unit, ResolveValueType(
            ValueType,
            @TypeOf(rhs.in(Self.Unit)),
        )) {
            const Rhs = @TypeOf(rhs);
            if (!Self.Unit.Dimension.equals(Rhs.Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            const right_val = if (Self.Unit.multiplier == Rhs.Unit.multiplier and
                Self.Unit.offset == Rhs.Unit.offset) rhs.value else rhs.in(Self.Unit);
            return .{ .value = coerciveArithmetic(
                self.value,
                right_val,
                .sub,
            ) };
        }

        pub inline fn times(
            self: Self,
            rhs: anytype,
        ) Quantity(
            Self.Unit.Of(@TypeOf(rhs).Unit),
            ResolveValueType(
                ValueType,
                if (isNumType(@TypeOf(rhs))) @TypeOf(rhs) else @TypeOf(rhs.in(Self.Unit)),
            ),
        ) {
            const right_val = if (isNumber(rhs)) blk: {
                break :blk rhs;
            } else rhs.in(Self.Unit);
            return .{ .value = coerciveArithmetic(
                self.value,
                right_val,
                .mul,
            ) };
        }

        pub inline fn div(
            self: Self,
            rhs: anytype,
        ) Quantity(
            Self.Unit.Per(@TypeOf(rhs).Unit),
            ResolveValueType(
                ValueType,
                if (isNumType(@TypeOf(rhs))) @TypeOf(rhs) else @TypeOf(rhs.in(Self.Unit)),
            ),
        ) {
            const right_val = if (isNumber(rhs)) blk: {
                break :blk rhs;
            } else rhs.in(Self.Unit);
            return .{ .value = coerciveArithmetic(
                self.value,
                right_val,
                .div,
            ) };
        }

        pub inline fn abs(self: Self) Quantity(
            Self.Unit,
            Self.ValueType,
        ) {
            return .{ .value = @abs(self.value) };
        }

        /// Uses std.math.pow for f32, f64. Otherwise, multiplies manually, not
        /// handling special cases.
        pub inline fn pow(self: Self, power: ValueType) Quantity(
            Self.Unit.Pow(power),
            ValueType,
        ) {
            if (ValueType == f32 or ValueType == f64) {
                return .{ .value = std.math.pow(ValueType, self.value, power) };
            } else if (ValueType == comptime_float) {
                comptime {
                    var new_val: comptime_float = 1;
                    for (0..@abs(power)) |_| {
                        new_val *= self.value;
                    }
                    return .{ .value = if (power < 0) 1.0 / new_val else new_val };
                }
            }
            var new_val: ValueType = 1;
            for (0..@abs(power)) |_| {
                new_val *= self.value;
            }
            return .{ .value = if (power < 0) 1.0 / new_val else new_val };
        }

        pub inline fn inv(self: Self) Quantity(Self.Unit.Inv(), ValueType) {
            return self.pow(-1);
        }

        // pub inline fn mod(self: Self, rhs: anytype) Quantity(Self.Unit, ValueType) {

        // }

        /// for comptime
        pub fn str(self: Self, PrintInUnit: type) []const u8 {
            comptime {
                return std.fmt.comptimePrint("{d}{s}", .{ self.in(PrintInUnit), PrintInUnit.abbreviation });
            }
        }

        /// for comptime
        pub fn fullStr(self: Self, PrintInUnit: type) []const u8 {
            comptime {
                return std.fmt.comptimePrint("{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
            }
        }

        /// TODO print in scientific notation if possible upon no space left error (or maybe try to detect this with heuristic)
        pub fn bufStr(self: Self, PrintInUnit: type, buf: []u8) std.fmt.BufPrintError![]const u8 {
            return std.fmt.bufPrint(buf, "{d}{s}", .{ self.in(PrintInUnit), PrintInUnit.abbreviation });
        }

        pub fn bufFullStr(self: Self, PrintInUnit: type, buf: []u8) std.fmt.BufPrintError![]const u8 {
            return std.fmt.bufPrint(buf, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }

        pub fn allocStr(self: Self, PrintInUnit: type, alloc: std.mem.Allocator) std.fmt.AllocPrintError![]const u8 {
            return std.fmt.allocPrint(alloc, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }

        pub fn allocFullStr(self: Self, PrintInUnit: type, alloc: std.mem.Allocator) std.fmt.AllocPrintError![]const u8 {
            return std.fmt.allocPrint(alloc, "{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }
    };
}

// Base Units
// TODO split up units and change all units to be expressed as relations to base units or other units in their file
pub const Unitless = BaseUnit(Dimensionless, "unitless", "u");
pub const Seconds = BaseUnit(Time, "seconds", "s");
pub const Meters = BaseUnit(Length, "meters", "m");
pub const Kilograms = BaseUnit(Mass, "kilograms", "kg");
pub const Amps = BaseUnit(Current, "amps", "A");
pub const Kelvin = BaseUnit(Temperature, "kelvin", "K");
pub const Moles = BaseUnit(Amount, "moles", "mol");
pub const Candelas = BaseUnit(Luminosity, "candelas", "cd");
pub const Rotations = BaseUnit(Angle, "rotations", "rot");

// Converted Units
pub const Yards = Feet.ScaledTo("yards", "yd", 1 / 12);
pub const Feet = Meters.ScaledTo("feet", "ft", 0.3048);
pub const Inches = Feet.ScaledTo("inches", "in", 12);
pub const Nanometers = Meters.ScaledTo("nanometers", "nm", 1_000_000_000);
pub const Micrometers = Meters.ScaledTo("micrometers", "μm", 1_000_000);
pub const Millimeters = Meters.ScaledTo("millimeters", "mm", 1000);
pub const Centimeters = Meters.ScaledTo("centimeters", "cm", 100);
pub const Decimeter = Meters.ScaledTo("decimeters", "dm", 10);
pub const Kilometers = Meters.ScaledTo("kilometers", "km", 0.001);
pub const Celsius = Kelvin.OffsetTo("degrees celsius", "°C", -272.15);
pub const Rankine = Kelvin.ScaledTo("degrees rankine", "°Ra", 1.8);
pub const Fahrenheit = Rankine.OffsetTo("degrees fahrenheit", "°F", -458.67);
pub const Nanoseconds = Seconds.ScaledTo("nanoseconds", "ns", 1_000_000_000);
pub const Microseconds = Seconds.ScaledTo("microseconds", "μs", 1_000_000);
pub const Milliseconds = Seconds.ScaledTo("milliseconds", "ms", 1000);
pub const Minutes = Seconds.ScaledTo("minutes", "min", 1 / 60);
pub const Hours = Minutes.ScaledTo("hours", "hr", 1 / 60);
pub const Days = Hours.ScaledTo("days", "d", 1 / 24);
pub const MeanMonth = Days.ScaledTo("months", "mo", 1 / 30.4375);
pub const MeanYears = Days.ScaledTo("years", "yr", 1 / 365.2425);
pub const Micrograms = Kilograms.ScaledTo("micrograms", "μg", 1_000_000_000);
pub const Milligrams = Kilograms.ScaledTo("milligrams", "mg", 1_000_000);
pub const Grams = Kilograms.ScaledTo("grams", "g", 1000);
pub const Pounds = Kilometers.ScaledTo("pounds", "lbs", 2.204623);
pub const Radians = Rotations.ScaledTo("radians", "rad", 2 * std.math.pi);
pub const Degrees = Rotations.ScaledTo("degrees", "°", 360);

// Derived Units
pub const SquareMeters = Meters.Of(Meters).Named("square meters", "m²");
pub const MetersPerSecond = Meters.Per(Seconds).Named("meters per second", "m/s");
pub const MetersPerSecondSquared = Meters.Per(Seconds.ToThe(2)).Named("meters per second squared", "m/s²");
pub const MetersPerSecondCubed = Meters.Per(Seconds.ToThe(3)).Named("meters per second cubed", "m/s³");
pub const Newtons = Kilograms.Of(MetersPerSecondSquared).Named("newtons", "N");
pub const Volts = Kilograms.Of(SquareMeters).Per(Seconds.ToThe(3)).Per(Amps).Named("volts", "V");
pub const Ohms = Volts.Per(Amps).Named("ohms", "Ω");
pub const NewtonMeters = Newtons.Of(Meters).Named("newton-meters", "Nm");
pub const KilogramMetersSquared = Kilograms.Of(Meters.ToThe(2)).Named("kilogram meters squared", "kg⋅m²");
pub const NewtonSeconds = Kilograms.Of(MetersPerSecond).Named("newton-second", "N⋅s");
pub const KilogramMetersPerSecond = NewtonSeconds.Named("kilogram meters per secon", "kg⋅m/s");
pub const RotationsPerSecond = Rotations.Per(Seconds).Named("rotations per second", "rot/s");
pub const RotationsPerSecondSquared = Rotations.Per(Seconds.ToThe(2)).Named("rotations per second squared", "rot/s²");
pub const Joules = NewtonMeters.Named("Joules", "J");
pub const Watts = Joules.Per(Seconds).Named("watts", "W");
pub const Hertz = Seconds.Inv().Named("hertz", "Hz");
pub const VoltSecondsPerMeter = Volts.Per(MetersPerSecond).Named("volt seconds per meter", "v⋅s/m"); // linear kV
pub const VoltSecondsSquaredPerMeter = Volts.Per(MetersPerSecondSquared).Named("volt seconds squared per meter", "v⋅s²/m"); // linear kA

// Converted Derived Units
pub const Milliohms = Ohms.ScaledTo("milliohms", "mΩ", 1000);
pub const Kiloohms = Ohms.ScaledTo("kiloohms", "kΩ", 0.001);
pub const Millijoules = Joules.ScaledTo("millijoules", "mJ", 1000);
pub const Kilojoules = Joules.ScaledTo("kilojoules", "kJ", 0.001);
pub const Milliwatt = Watts.ScaledTo("milliwaitts", "mW", 1000);
pub const Kilowatt = Watts.ScaledTo("kilowatts", "kW", 0.001);
pub const Horsepower = Watts.ScaledTo("horsepower", "hp", 745.7);
pub const FeetPerSecond = Feet.Per(Seconds).Named("feet per second", "ft/s");
pub const FeetPerSecondSquared = FeetPerSecond.Per(Seconds).Named("feet per second squared", "ft/s²");
pub const RotationsPerMinute = Rotations.Per(Minutes).Named("rotations per minute", "rot/min");
pub const RotationsPerMinuteSquared = RotationsPerMinute.Per(Minutes).Named("rotations per minute squared", "rot/min²");
pub const RadiansPerSecond = Radians.Per(Seconds).Named("radians per second", "rad/s");
pub const RadiansPerSecondSquared = RadiansPerSecond.Per(Seconds).Named("radians per second squared", "rad/s²");
pub const DegreesPerSecond = Degrees.Per(Seconds).Named("degrees per second", "deg/s");
pub const DegreesPerSecondSquared = DegreesPerSecond.Per(Seconds).Named("degrees per second squared", "deg/s²");
pub const VoltSecondsPerRadian = Volts.Per(RadiansPerSecond).Named("volt seconds per radian", "v⋅s/rad"); // angular kV
pub const VoltSecondsSquaredPerRadian = Volts.Per(RadiansPerSecondSquared).Named("volt seconds squared per radian", "v⋅s²/rad"); // angular kA

// recommended by std lib
const f128_tol = std.math.sqrt(std.math.floatEps(f128));
const f16_tol = std.math.sqrt(std.math.floatEps(f16));
test "Create quantities" {
    try testing.expectEqual(Meters.of(3).value, 3);
}

test "Converting units" {
    try testing.expectApproxEqRel(
        @as(f128, 0.9144),
        Feet.of(3).in(Meters),
        f128_tol,
    );
}

test "Adding and subtracting same units" {
    try testing.expectEqual(
        4,
        Feet.of(3).plus(Feet.of(1)).in(Feet),
    );
}

test "Adding and subtracting same dimensions" {
    try testing.expectApproxEqRel(
        @as(f128, -0.0856),
        Feet.of(3).minus(Meters.of(1)).in(Meters),
        f128_tol,
    );
}

test "Multiplying dimensions" {
    const mkg = Meters.of(2).times(Kilograms.of(5));
    try testing.expect(@TypeOf(mkg).Unit.Dimension.equals(Dimension(
        0,
        1,
        1,
        0,
        0,
        0,
        0,
        0,
    )));
    try testing.expectApproxEqRel(
        @as(f128, 10),
        mkg.in(Meters.Of(Kilograms)),
        f128_tol,
    );
}

test "Dividing dimensions" {
    const mps = Meters.of(7).div(Seconds.of(2));
    try testing.expect(@TypeOf(mps).Unit.Dimension.equals(Dimension(
        -1,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
    )));
    try testing.expectApproxEqRel(
        @as(f128, 3.5),
        mps.in(Meters.Per(Seconds)),
        f128_tol,
    );
}

test "Runtime arithmetic" {
    const a = Meters.of(2);
    const b = Meters.of(@as(i7, 20));
    const c = Meters.of(@as(f32, 34));
    const d = Seconds.of(@as(i64, 3));

    try testing.expectEqual(a.plus(b.as(f32)), b.as(f32).plus(a));
    try testing.expectEqual(a.minus(c).abs(), c.minus(a));
    try testing.expectEqual(b.plus(c), c.plus(b));
    try testing.expectEqual(
        a.times(d).in(Meters.Of(Seconds)),
        d.times(a).in(Meters.Of(Seconds)),
    );
}

test "Runtime division" {
    const a = Radians.of(@as(i6, 20));
    const b = Newtons.of(@as(f16, 7));
    try testing.expectApproxEqRel(
        a.div(b).in(Radians.Per(Newtons)),
        b.inv().times(a).in(Radians.Per(Newtons)),
        f16_tol,
    );

    const c = Newtons.of(@as(f128, 9));
    try testing.expectApproxEqRel(
        a.as(f128).div(c).in(Radians.Per(Newtons)),
        c.inv().times(a.as(f128)).in(Radians.Per(Newtons)),
        f128_tol,
    );
}

test "Pow" {
    const val = Radians.of(10);
    try testing.expectEqual(val.times(val), val.pow(2));

    const val2 = Watts.of(@as(f64, 17));
    try testing.expectEqual(val2.times(val2), val2.pow(2));
}

test "Units maintain identity and inverse properties of multiplication" {
    // there are, of course, absurdly large/precise values where this does not hold
    // in those cases, floating point arithmetic is likely not appropriate anyways
    const a = meters(1592287654567656789765787689878989876543234567654345678987654567345676543248472).div(Seconds.of(@as(f32, 2.123425))).times(Seconds.of(0.098765434569999999999997865435678654679999999999999978));
    try std.testing.expect(Length.equals(@TypeOf(a).Unit.Dimension));
    try std.testing.expect(Meters.equals(@TypeOf(a).Unit));

    const b = radians(123456789).times(meters(@as(f32, 0.123456789654))).div(meters(34253));
    try std.testing.expect(Angle.equals(@TypeOf(b).Unit.Dimension));
    try std.testing.expect(Radians.equals(@TypeOf(b).Unit));

    const c = radians(123456789).times(meters(@as(i32, 5))).div(meters(34253));
    try std.testing.expect(Angle.equals(@TypeOf(c).Unit.Dimension));
    try std.testing.expect(Radians.equals(@TypeOf(c).Unit));
}

const meters = &Meters.of;
const radians = &Radians.of;
