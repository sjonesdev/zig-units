//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
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

// fn Dimension(dimensions_in: []const struct { component: DimensionComponent, power: comptime_int }) type {
fn Dimension(
    t_in: comptime_int,
    l_in: comptime_int,
    m_in: comptime_int,
    i_in: comptime_int,
    d_in: comptime_int,
    n_in: comptime_int,
    j_in: comptime_int,
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
        // const dimensions = dimensions_in;

        // const str = makeStr();
        const str = std.fmt.comptimePrint(
            "{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d},{u}:{d}",
            .{
                @intFromEnum(DimensionComponent.time),       t,
                @intFromEnum(DimensionComponent.length),     l,
                @intFromEnum(DimensionComponent.mass),       m,
                @intFromEnum(DimensionComponent.current),    i,
                @intFromEnum(DimensionComponent.temp),       d,
                @intFromEnum(DimensionComponent.amount),     n,
                @intFromEnum(DimensionComponent.luminosity), j,
            },
        );

        // fn makeStr() []const u8 {
        //     var str_in = "";
        //     for (dimensions_in) |dim| {
        //         str_in = str_in ++ std.fmt.comptimePrint("{u}:{d},", .{ dim.component, dim.power });
        //     }
        //     str_in = if (str_in.len == 0) {
        //         std.fmt.comptimePrint("{u}", .{@intFromEnum(DimensionComponent.none)});
        //     } else {
        //         str_in[0 .. str_in.len - 1];
        //     };
        //     return str_in;
        // }

        pub fn MultipliedBy(Dim: type) type {
            return Dimension(
                t + Dim.t,
                l + Dim.l,
                m + Dim.m,
                i + Dim.i,
                d + Dim.d,
                n + Dim.n,
                j + Dim.j,
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
            );
        }

        pub inline fn equals(Dim: type) bool {
            return t == Dim.t and
                l == Dim.l and
                m == Dim.m and
                i == Dim.i and
                d == Dim.d and
                n == Dim.n and
                j == Dim.j;
        }
    };
}

/// Used to create a dimension orthogonal to all other existing base dimensions.
/// This can be used to add custom dimensions (e.g. dollars), or encode semantics
/// into an existing dimension to treat them as orthogonal.
pub fn BaseDimension(comptime dim: DimensionComponent) type {
    const Dim = Dimension(
        if (dim == .time) 1 else 0,
        if (dim == .length) 1 else 0,
        if (dim == .mass) 1 else 0,
        if (dim == .current) 1 else 0,
        if (dim == .temp) 1 else 0,
        if (dim == .amount) 1 else 0,
        if (dim == .luminosity) 1 else 0,
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
pub const Dimensionless = BaseDimension(.none);

// Compound Dimensions
pub const Velocity = Length.DividedBy(Time);
pub const Acceleration = Velocity.DividedBy(Time);
pub const Jerk = Acceleration.DividedBy(Time);
pub const Force = Mass.MultipliedBy(Acceleration);
pub const Area = Length.MultipliedBy(Length);
pub const Pressure = Force.DividedBy(Area);
pub const Energy = Force.MultipliedBy(Length);
pub const Power = Energy.DividedBy(Time);
pub const Charge = Current.MultipliedBy(Time);
pub const Voltage = Power.DividedBy(Current);
pub const Capacitance = Charge.DividedBy(Voltage);
pub const Frequency = Dimensionless.DividedBy(Seconds);
// momentum
// moi
// torque
// resistance
//

fn Unit(DimensionIn: type, name_in: []const u8, multiplier_in: comptime_float, offset_in: comptime_float) type {
    return struct {
        const Self = @This();
        const Dimension = DimensionIn;
        pub const name = name_in;
        const multiplier = multiplier_in;
        const offset = offset_in;

        pub fn ScaledTo(unit_name: []const u8, scale_factor: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
                scale_factor * multiplier,
                offset * multiplier,
            );
        }

        pub fn OffsetTo(unit_name: []const u8, offset_value: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
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

        pub inline fn Per(RightUnit: type) type {
            return DerivedUnit(
                @This(),
                RightUnit,
                .divide,
            );
        }

        pub inline fn of(value: comptime_float) Quantity(Self) {
            return .{ .value = value };
        }

        pub inline fn ofBase(value: comptime_float) Quantity(Self) {
            return .{ .value = value * multiplier + offset };
        }
    };
}

const UnitCombinationOperation = enum { multiply, divide };
fn DerivedUnit(
    left_hand_unit: type,
    right_hand_unit: type,
    operation: UnitCombinationOperation,
) type {
    // if(unit already exists) return existing unit
    if (left_hand_unit.offset != 0 or right_hand_unit.offset != 0) {
        @compileError("Deriving from an offset unit is not allowed");
    }
    const Dim: type, const join_word: []const u8, const mult: comptime_float = switch (operation) {
        .multiply => .{
            left_hand_unit.Dimension.MultipliedBy(right_hand_unit.Dimension),
            "",
            left_hand_unit.multiplier * right_hand_unit.multiplier,
        },
        .divide => .{
            left_hand_unit.Dimension.DividedBy(right_hand_unit.Dimension),
            "Per",
            left_hand_unit.multiplier / right_hand_unit.multiplier,
        },
    };

    return Unit(
        Dim,
        left_hand_unit.name ++ join_word ++ right_hand_unit.name,
        mult,
        0,
    );
}

/// There should only be one base unit per dimension
fn BaseUnit(DimensionIn: type, name_in: []const u8) type {
    return Unit(DimensionIn, name_in, 1, 0);
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
            return RightUnit.ofBase(self.baseValue()).value;
        }

        pub inline fn plus(self: Self, rhs: anytype) Self {
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
    };
}

// Base Units
pub const Seconds = BaseUnit(Time, "Seconds");
pub const Meters = BaseUnit(Length, "Meters");
pub const Kilograms = BaseUnit(Mass, "Kilograms");
pub const Amps = BaseUnit(Current, "Amps");
pub const Kelvin = BaseUnit(Temperature, "Kelvin");
pub const Moles = BaseUnit(Amount, "Moles");
pub const Candelas = BaseUnit(Luminosity, "Candela");

// Scaled Units
pub const Feet = Meters.ScaledTo("Feet", 3.2808399);
// TODO
// yard, inch, centimeter, kilometer, decimeter, volts,
// fahreinheit, celcius, microseconds, nanoseconds, milliseconds,
// minute, hours, days, years, weeks, jerk, momentum, moi, torque,
// ohms, milliamps, milliohms, kiloomhms, joules, millijoules, kilojoules, watt
// kilowatt, milliwat, hp, motor characterization units

// Derived Units
pub const MetersPerSecond = Meters.Per(Seconds);
pub const MetersPerSecondSquared = MetersPerSecond.Per(Seconds);
pub const Newton = Kilograms.Of(MetersPerSecondSquared);

const tol = 0.0000001;
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
    )));
    try testing.expectApproxEqAbs(
        @as(f128, 3.5),
        mps.in(Meters.Per(Seconds)),
        tol,
    );
}

test "functionality" {
    // const
}
