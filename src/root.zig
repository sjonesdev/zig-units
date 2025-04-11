const std = @import("std");
const testing = std.testing;

inline fn isNumber(val: anytype) bool {
    return switch (@typeInfo(@TypeOf(val))) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
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

fn Unit(DimensionIn: type, name_in: []const u8, abbreviation_in: []const u8, multiplier_in: comptime_float, offset_in: comptime_float) type {
    return struct {
        const Self = @This();
        const Dimension = DimensionIn;
        pub const name = name_in;
        pub const abbreviation = abbreviation_in;
        const multiplier = multiplier_in;
        const offset = offset_in;

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

        pub fn Of(RightUnit: type) type { // maybe rename to Dot?
            return DerivedUnit(
                @This(),
                RightUnit,
                .multiply,
            );
        }

        pub fn Per(RightUnit: type) type {
            return DerivedUnit(
                @This(),
                RightUnit,
                .divide,
            );
        }

        pub fn ToThe(power: comptime_int) type {
            if (power < 0) {
                @compileError("ToThe only supports integers >0");
            }
            var Result = Self;
            for (1..power) |_| {
                Result = Result.Of(Self);
            }
            return Result;
        }

        pub fn Inverted() type {
            return Unitless.Per(Self);
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

    if (Dim.isBase()) {
        @compileError(std.fmt.comptimePrint(
            "Cannot derive a base unit: ({s}) {s} ({s})",
            .{ LeftHandUnit.name, @tagName(operation), RightHandUnit.name },
        ));
    }

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

fn Quantity(UnitIn: type, ValueTypeIn: type) type {
    return struct {
        const Self = @This();
        const Unit = UnitIn;
        const ValueType = ValueTypeIn;

        value: ValueType,

        inline fn baseValue(self: Self) ValueType {
            return (self.value - Self.Unit.offset) / Self.Unit.multiplier;
        }

        // TODO output float from here and make a "to" method instead for converting internal representation
        inline fn in(self: Self, RightUnit: type) ValueType {
            return @mulAdd(ValueType, self.baseValue(), RightUnit.multiplier, RightUnit.offset);
        }

        pub inline fn plus(
            self: Self,
            rhs: anytype,
        ) Quantity(Self.Unit, @TypeOf(self.value + rhs.in(Self.Unit))) {
            // TODO handle pointers to quantities (either by literally handling them or providing a custom error message)
            if (!Self.Unit.Dimension.equals(@TypeOf(rhs).Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            return .{ .value = self.value + rhs.in(Self.Unit) };
        }
        // if (ValueType == comptime_float) @TypeOf(rhs).ValueType else ValueType,

        pub inline fn minus(
            self: Self,
            rhs: anytype,
        ) Quantity(Self.Unit, @TypeOf(self.value + rhs.in(Self.Unit))) {
            if (!Self.Unit.Dimension.equals(@TypeOf(rhs).Unit.Dimension)) {
                @compileError("Subtracting different dimensions in not allowed");
            }
            return .{ .value = self.value - rhs.in(Self.Unit) };
        }

        pub inline fn times(
            self: Self,
            rhs: anytype,
        ) Quantity(Self.Unit.Of(@TypeOf(rhs).Unit), @TypeOf(self.value * rhs.in(Self.Unit))) {
            if (isNumber(rhs)) {
                return .{ .value = self.value * rhs };
            }
            return .{ .value = self.value * rhs.in(Self.Unit) };
        }

        pub inline fn div(
            self: Self,
            rhs: anytype,
        ) Quantity(Self.Unit.Per(@TypeOf(rhs).Unit), @TypeOf(self.value / rhs.in(Self.Unit))) {
            if (isNumber(rhs)) {
                return .{ .value = self.value / rhs };
            }
            return .{ .value = self.value / rhs.in(Self.Unit) };
        }

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

        // TODO create function with built in buffer
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
pub const Yards = Meters.ScaledTo("yards", "yd", 1.093613);
pub const Feet = Yards.ScaledTo("feet", "ft", 3);
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
pub const Hertz = Unitless.Per(Seconds).Named("hertz", "Hz");
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

const tol = 0.00001;
test "Create quantities" {
    try testing.expectEqual(Meters.of(3).value, 3);
}

test "Converting units" {
    try testing.expectApproxEqAbs(
        @as(f128, 0.9144),
        Feet.of(3).in(Meters),
        tol,
    );
}

test "Adding and subtracting same units" {
    try testing.expectEqual(
        4,
        Feet.of(3).plus(Feet.of(1)).in(Feet),
    );
}

test "Adding and subtracting same dimensions" {
    try testing.expectApproxEqAbs(
        @as(f128, -0.0856),
        Feet.of(3).minus(Meters.of(1)).in(Meters),
        tol,
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
    try testing.expectApproxEqAbs(
        @as(f128, 10),
        mkg.in(Meters.Of(Kilograms)),
        tol,
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
    try testing.expectApproxEqAbs(
        @as(f128, 3.5),
        mps.in(Meters.Per(Seconds)),
        tol,
    );
}

test "Runtime arithmetic" {
    var m1 = try std.testing.allocator.create(Quantity(Meters, f64));
    m1.* = .{ .value = 100 };
    defer std.testing.allocator.destroy(m1);
    var buf: [256]u8 = undefined;
    std.debug.print("{s}\n", .{(try m1.bufStr(Meters, &buf))});

    const m2 = Meters.of(10);
    const m3 = m1.plus(m2);
    std.debug.print("{s}\n", .{(try m3.bufStr(Meters, &buf))});
    const m4 = m2.plus(m1.*);
    std.debug.print("{s}\n", .{(try m4.bufStr(Meters, &buf))});

    const m5 = try std.testing.allocator.create(Quantity(Meters, f32));
    defer std.testing.allocator.destroy(m5);
    m5.* = .{ .value = 69 };
    const m6 = m5.plus(m2);
    std.debug.print("{s}\n", .{(try m6.bufStr(Meters, &buf))});

    const m7 = m2.plus(m5.*);
    std.debug.print("{s}\n", .{(try m7.bufStr(Meters, &buf))});

    const m8 = m5.plus(m1.*);
    std.debug.print("{s}\n", .{(try m8.bufStr(Meters, &buf))});

    const m9 = m1.plus(m5.*);
    std.debug.print("{s}\n", .{(try m9.bufStr(Meters, &buf))});
}
