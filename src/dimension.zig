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
pub const Frequency = Dimensionless.DividedBy(Time);
pub const Torque = Energy;
pub const Momentum = Torque.DividedBy(Time);
pub const Impulse = Momentum;
pub const MomentOfInertia = Torque.MultipliedBy(Length);
pub const Resistance = Voltage.DividedBy(Current);

test "Multiplying dimensions" {
    const lm = Length.MultipliedBy(Mass);
    try testing.expect(lm == Dimension(
        0,
        1,
        1,
        0,
        0,
        0,
        0,
        0,
    ));
}

test "Dividing dimensions" {
    const tl = Length.DividedBy(Time);
    try testing.expect(tl == Dimension(
        -1,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
    ));
}
