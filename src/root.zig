const std = @import("std");
const testing = std.testing;

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
pub const Torque = Mass.MultipliedBy(Length);
pub const Momentum = Torque.DividedBy(Time);
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

        pub fn ConvertedTo(unit_name: []const u8, unit_abbreviation: []const u8, conversion_factor: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
                unit_abbreviation,
                conversion_factor * multiplier,
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

        pub fn Named(new_name: []const u8, new_abbreviation: []const u8) type {
            if (Self.Dimension.isBase()) {
                @compileError(std.fmt.comptimePrint("Cannot rename base unit {s}", .{name}));
            }
            return Unit(
                Self.Dimension,
                new_name,
                new_abbreviation,
                multiplier,
                offset,
            );
        }

        pub inline fn of(value: comptime_float) Quantity(Self) {
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

/// There should only be one base unit per dimension
fn BaseUnit(DimensionIn: type, name_in: []const u8, abbreviation_in: []const u8) type {
    return Unit(DimensionIn, name_in, abbreviation_in, 1, 0);
}

fn Quantity(UnitIn: type) type {
    return struct {
        const Self = @This();
        const Unit = UnitIn;

        value: comptime_float,

        inline fn baseValue(self: Self) comptime_float {
            return (self.value - Self.Unit.offset) / Self.Unit.multiplier;
        }

        // TODO output float from here and make a "to" method instead for converting internal representation
        inline fn in(self: Self, RightUnit: type) comptime_float {
            return @mulAdd(comptime_float, self.baseValue(), RightUnit.multiplier, RightUnit.offset);
        }

        pub inline fn plus(self: Self, rhs: anytype) Self { // if I changed the quantities to be defined by their base units I could define the rhs type more concretely as Self, that would also limit type cardinality and potentially improve compile times
            if (!Self.Unit.Dimension.equals(@TypeOf(rhs).Unit.Dimension)) {
                @compileError("Adding different dimensions in not allowed");
            }
            return .{ .value = self.value + rhs.in(Self.Unit) };
        }

        pub inline fn minus(self: Self, rhs: anytype) Self {
            if (!Self.Unit.Dimension.equals(@TypeOf(rhs).Unit.Dimension)) {
                @compileError("Subtracting different dimensions in not allowed");
            }
            return .{ .value = self.value - rhs.in(Self.Unit) };
        }

        pub inline fn times(self: Self, rhs: anytype) Quantity(Self.Unit.Of(@TypeOf(rhs).Unit)) {
            return .{ .value = self.value * rhs.in(Self.Unit) };
        }

        pub inline fn div(self: Self, rhs: anytype) Quantity(Self.Unit.Per(@TypeOf(rhs).Unit)) {
            return .{ .value = self.value / rhs.in(Self.Unit) };
        }

        pub fn str(self: Self, PrintInUnit: type) []const u8 {
            return std.fmt.comptimePrint("{d}{s}", .{ self.in(PrintInUnit), PrintInUnit.abbreviation });
        }

        pub fn fullStr(self: Self, PrintInUnit: type) []const u8 {
            return std.fmt.comptimePrint("{d} {s}", .{ self.in(PrintInUnit), PrintInUnit.name });
        }

        // TODO make abbreviated string fn as well "str"
    };
}

// Base Units
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
pub const Yards = Meters.ConvertedTo("yards", "yd", 1.093613);
pub const Feet = Yards.ConvertedTo("feet", "ft", 3);
pub const Inches = Feet.ConvertedTo("inches", "in", 12);
pub const Nanometers = Meters.ConvertedTo("nanometers", "nm", 1_000_000_000);
pub const Micrometers = Meters.ConvertedTo("micrometers", "μm", 1_000_000);
pub const Millimeters = Meters.ConvertedTo("millimeters", "mm", 1000);
pub const Centimeters = Meters.ConvertedTo("centimeters", "cm", 100);
pub const Decimeter = Meters.ConvertedTo("decimeters", "dm", 10);
pub const Kilometers = Meters.ConvertedTo("kilometers", "km", 0.001);
pub const Celsius = Kelvin.OffsetTo("degrees celsius", "°C", -272.15);
pub const Rankine = Kelvin.ConvertedTo("degrees rankine", "°Ra", 1.8);
pub const Fahrenheit = Rankine.OffsetTo("degrees fahrenheit", "°F", -458.67);
pub const Nanoseconds = Seconds.ConvertedTo("nanoseconds", "ns", 1_000_000_000);
pub const Microseconds = Seconds.ConvertedTo("microseconds", "μs", 1_000_000);
pub const Milliseconds = Seconds.ConvertedTo("milliseconds", "ms", 1000);
pub const Minutes = Seconds.ConvertedTo("minutes", "min", 1 / 60);
pub const Hours = Minutes.ConvertedTo("hours", "hr", 1 / 60);
pub const Days = Hours.ConvertedTo("days", "d", 1 / 24);
pub const MeanMonth = Days.ConvertedTo("months", "mo", 1 / 30.4375);
pub const MeanYears = Days.ConvertedTo("years", "yr", 1 / 365.2425);

// TODO
// ohms, milliamps, milliohms, kiloomhms, joules, millijoules, kilojoules, watt
// kilowatt, milliwat, hp, motor characterization units

// Derived Units
pub const SquareMeters = Meters.Of(Meters).Named("square meters", "m²");
pub const MetersPerSecond = Meters.Per(Seconds);
pub const MetersPerSecondSquared = Meters.Per(Seconds.ToThe(2)).Named("meters per second squared", "m/s²");
pub const MetersPerSecondCubed = Meters.Per(Seconds.ToThe(3));
pub const Newtons = Kilograms.Of(MetersPerSecondSquared);
pub const Volts = Kilograms.Of(SquareMeters).Per(Seconds.ToThe(3)).Per(Amps);
pub const Ohms = Volts.Per(Amps);
pub const NewtonMeters = Newtons.Of(Meters);
pub const KilogramMetersSquared = Kilograms.Of(Meters.ToThe(2));
pub const NewtonSecond = Kilograms.Of(MetersPerSecond);
pub const RotationsPerSecond = Rotations.Per(Seconds);
pub const RotationsPerSecondSquared = Rotations.Per(Seconds.ToThe(2));

// feet per second
// rot/rad/deg per min/sec/sec^2

// Converted Derived Units

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

test "functionality" {
    std.debug.print("{s}\n", .{MetersPerSecondSquared.of(2).str(MetersPerSecondSquared)});
    std.debug.print("{s}\n", .{Volts.name});
}
