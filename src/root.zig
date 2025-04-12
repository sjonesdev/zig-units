const std = @import("std");
const math = std.math;
const testing = std.testing;

const unit = @import("unit.zig");
const dim = @import("dimension.zig");
const quantity = @import("quantity.zig");
const Quantity = quantity.Quantity;

// Base Units
pub const Unitless = unit.Unitless;
const unitless = Unitless.of;
pub const Seconds = unit.BaseUnit(dim.Time, "seconds", "s");
const seconds = Seconds.of;
pub const Meters = unit.BaseUnit(dim.Length, "meters", "m");
const meters = Meters.of;
pub const Kilograms = unit.BaseUnit(dim.Mass, "kilograms", "kg");
const kilograms = Kilograms.of;
pub const Amps = unit.BaseUnit(dim.Current, "amps", "A");
const amps = Amps.of;
pub const Kelvin = unit.BaseUnit(dim.Temperature, "kelvin", "K");
const kelvin = Kelvin.of;
pub const Moles = unit.BaseUnit(dim.Amount, "moles", "mol");
const moles = Moles.of;
pub const Candelas = unit.BaseUnit(dim.Luminosity, "candelas", "cd");
const candelas = Candelas.of;
pub const Rotations = unit.BaseUnit(dim.Angle, "rotations", "rot");
const rotations = Rotations.of;
// could also do this but it is a lot of boiler plate, but does avoid circular imports
// const meters = struct {
//     inline fn of(value: anytype) Quantity(Meters, @TypeOf(value)) {
//         return .{ .value = quantity.of(Meters, value) };
//     }
// }.of;

// Converted Units
pub const Yards = Feet.ScaledTo("yards", "yd", 1.0 / 3.0);
pub const yards = Yards.of;
pub const Feet = Meters.ScaledTo("feet", "ft", 1.0 / 0.3048);
pub const feet = Feet.of;
pub const Inches = Feet.ScaledTo("inches", "in", 12);
pub const inches = Inches.of;
pub const Parsecs = Meters.ScaledTo("parsecs", "pc", 1.0 / 3.0857e16);
pub const Nanometers = Meters.ScaledTo("nanometers", "nm", 1_000_000_000);
pub const nanometers = Nanometers.of;
pub const Micrometers = Meters.ScaledTo("micrometers", "μm", 1_000_000);
pub const micrometers = Micrometers.of;
pub const Millimeters = Meters.ScaledTo("millimeters", "mm", 1000);
pub const millimeters = Millimeters.of;
pub const Centimeters = Meters.ScaledTo("centimeters", "cm", 100);
pub const centimeters = Centimeters.of;
pub const Decimeters = Meters.ScaledTo("decimeters", "dm", 10);
pub const decimeters = Decimeters.of;
pub const Kilometers = Meters.ScaledTo("kilometers", "km", 0.001);
pub const kilometers = Kilometers.of;
pub const Celsius = Kelvin.OffsetTo("degrees celsius", "°C", -272.15);
pub const celsius = Celsius.of;
pub const Rankine = Kelvin.ScaledTo("degrees rankine", "°Ra", 1.8);
pub const rankine = Rankine.of;
pub const Fahrenheit = Rankine.OffsetTo("degrees fahrenheit", "°F", -458.67);
pub const fahrenheit = Fahrenheit.of;
pub const Nanoseconds = Seconds.ScaledTo("nanoseconds", "ns", 1_000_000_000);
pub const nanoseconds = Nanoseconds.of;
pub const Microseconds = Seconds.ScaledTo("microseconds", "μs", 1_000_000);
pub const microseconds = Microseconds.of;
pub const Milliseconds = Seconds.ScaledTo("milliseconds", "ms", 1000);
pub const milliseconds = Milliseconds.of;
pub const Minutes = Seconds.ScaledTo("minutes", "min", 1.0 / 60.0);
pub const minutes = Minutes.of;
pub const Hours = Minutes.ScaledTo("hours", "hr", 1.0 / 60.0);
pub const hours = Hours.of;
pub const Days = Hours.ScaledTo("days", "d", 1.0 / 24.0);
pub const days = Days.of;
pub const MeanMonth = Days.ScaledTo("months", "mo", 1.0 / 30.4375);
pub const meanMonth = MeanMonth.of;
pub const MeanYears = Days.ScaledTo("years", "yr", 1.0 / 365.2425);
pub const meanYears = MeanYears.of;
pub const Micrograms = Kilograms.ScaledTo("micrograms", "μg", 1_000_000_000);
pub const micrograms = Micrograms.of;
pub const Milligrams = Kilograms.ScaledTo("milligrams", "mg", 1_000_000);
pub const milligrams = Milligrams.of;
pub const Grams = Kilograms.ScaledTo("grams", "g", 1000);
pub const grams = Grams.of;
pub const Pounds = Kilometers.ScaledTo("pounds", "lbs", 2.204623);
pub const pounds = Pounds.of;
pub const Radians = Rotations.ScaledTo("radians", "rad", 2 * math.pi);
pub const radians = Radians.of;
pub const Degrees = Rotations.ScaledTo("degrees", "°", 360);
pub const degrees = Degrees.of;

// Derived Units
pub const SquareMeters = Meters.Of(Meters).Named("square meters", "m²");
pub const squareMeters = SquareMeters.of;
pub const MetersPerSecond = Meters.Per(Seconds).Named("meters per second", "m/s");
pub const metersPerSecond = MetersPerSecond.of;
pub const MetersPerSecondSquared = Meters.Per(Seconds.ToThe(2)).Named("meters per second squared", "m/s²");
pub const metersPerSecondSquared = MetersPerSecondSquared.of;
pub const MetersPerSecondCubed = Meters.Per(Seconds.ToThe(3)).Named("meters per second cubed", "m/s³");
pub const metersPerSecondCubed = MetersPerSecondCubed.of;
pub const Newtons = Kilograms.Of(MetersPerSecondSquared).Named("newtons", "N");
pub const newtons = Newtons.of;
pub const Volts = Kilograms.Of(SquareMeters).Per(Seconds.ToThe(3)).Per(Amps).Named("volts", "V");
pub const volts = Volts.of;
pub const Ohms = Volts.Per(Amps).Named("ohms", "Ω");
pub const ohms = Ohms.of;
pub const NewtonMeters = Newtons.Of(Meters).Named("newton-meters", "Nm");
pub const newtonMeters = NewtonMeters.of;
pub const KilogramMetersSquared = Kilograms.Of(Meters.ToThe(2)).Named("kilogram meters squared", "kg⋅m²");
pub const kilogramMetersSquared = KilogramMetersSquared.of;
pub const NewtonSeconds = Kilograms.Of(MetersPerSecond).Named("newton-second", "N⋅s");
pub const newtonSeconds = NewtonSeconds.of;
pub const KilogramMetersPerSecond = NewtonSeconds.Named("kilogram meters per secon", "kg⋅m/s");
pub const kilogramMetersPerSecond = KilogramMetersPerSecond.of;
pub const RotationsPerSecond = Rotations.Per(Seconds).Named("rotations per second", "rot/s");
pub const rotationsPerSecond = RotationsPerSecond.of;
pub const RotationsPerSecondSquared = Rotations.Per(Seconds.ToThe(2)).Named("rotations per second squared", "rot/s²");
pub const rotationsPerSecondSquared = RotationsPerSecondSquared.of;
pub const Joules = NewtonMeters.Named("Joules", "J");
pub const joules = Joules.of;
pub const Watts = Joules.Per(Seconds).Named("watts", "W");
pub const watts = Watts.of;
pub const Hertz = Seconds.Inv().Named("hertz", "Hz");
pub const hertz = Hertz.of;
pub const VoltSecondsPerMeter = Volts.Per(MetersPerSecond).Named("volt seconds per meter", "v⋅s/m"); // linear kV
pub const voltSecondsPerMeter = VoltSecondsPerMeter.of;
pub const VoltSecondsSquaredPerMeter = Volts.Per(MetersPerSecondSquared).Named("volt seconds squared per meter", "v⋅s²/m"); // linear kA
pub const voltSecondsSquaredPerMeter = VoltSecondsSquaredPerMeter.of;

// Converted Derived Units
pub const Milliohms = Ohms.ScaledTo("milliohms", "mΩ", 1000);
pub const milliohms = Milliohms.of;
pub const Kiloohms = Ohms.ScaledTo("kiloohms", "kΩ", 0.001);
pub const kiloohms = Kiloohms.of;
pub const Millijoules = Joules.ScaledTo("millijoules", "mJ", 1000);
pub const millijoules = Millijoules.of;
pub const Kilojoules = Joules.ScaledTo("kilojoules", "kJ", 0.001);
pub const kilojoules = Kilojoules.of;
pub const Milliwatt = Watts.ScaledTo("milliwaitts", "mW", 1000);
pub const milliwatt = Milliwatt.of;
pub const Kilowatt = Watts.ScaledTo("kilowatts", "kW", 0.001);
pub const kilowatt = Kilowatt.of;
pub const Horsepower = Watts.ScaledTo("horsepower", "hp", 745.7);
pub const horsepower = Horsepower.of;
pub const FeetPerSecond = Feet.Per(Seconds).Named("feet per second", "ft/s");
pub const feetPerSecond = FeetPerSecond.of;
pub const FeetPerSecondSquared = FeetPerSecond.Per(Seconds).Named("feet per second squared", "ft/s²");
pub const feetPerSecondSquared = FeetPerSecondSquared.of;
pub const RotationsPerMinute = Rotations.Per(Minutes).Named("rotations per minute", "rot/min");
pub const rotationsPerMinute = RotationsPerMinute.of;
pub const RotationsPerMinuteSquared = RotationsPerMinute.Per(Minutes).Named("rotations per minute squared", "rot/min²");
pub const rotationsPerMinuteSquared = RotationsPerMinuteSquared.of;
pub const RadiansPerSecond = Radians.Per(Seconds).Named("radians per second", "rad/s");
pub const radiansPerSecond = RadiansPerSecond.of;
pub const RadiansPerSecondSquared = RadiansPerSecond.Per(Seconds).Named("radians per second squared", "rad/s²");
pub const radiansPerSecondSquared = RadiansPerSecondSquared.of;
pub const DegreesPerSecond = Degrees.Per(Seconds).Named("degrees per second", "deg/s");
pub const degreesPerSecond = DegreesPerSecond.of;
pub const DegreesPerSecondSquared = DegreesPerSecond.Per(Seconds).Named("degrees per second squared", "deg/s²");
pub const degreesPerSecondSquared = DegreesPerSecondSquared.of;
pub const VoltSecondsPerRadian = Volts.Per(RadiansPerSecond).Named("volt seconds per radian", "v⋅s/rad"); // angular kV
pub const voltSecondsPerRadian = VoltSecondsPerRadian.of;
pub const VoltSecondsSquaredPerRadian = Volts.Per(RadiansPerSecondSquared).Named("volt seconds squared per radian", "v⋅s²/rad"); // angular kA
pub const voltSecondsSquaredPerRadian = VoltSecondsSquaredPerRadian.of;

// recommended by std lib
const f128_tol = math.sqrt(math.floatEps(f128));
const f16_tol = math.sqrt(math.floatEps(f16));
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

test "Multiplying" {
    const mkg = Meters.of(2).times(Kilograms.of(5));
    try testing.expect(@TypeOf(mkg).Unit.Dimension.equals(dim.Length.MultipliedBy(dim.Mass)));
    try testing.expectApproxEqRel(
        @as(f128, 10),
        mkg.in(Meters.Of(Kilograms)),
        f128_tol,
    );
}

test "Dividing" {
    const mps = Meters.of(7).div(Seconds.of(2));
    try testing.expect(@TypeOf(mps).Unit.Dimension.equals(dim.Length.DividedBy(dim.Time)));
    try testing.expectEqual(
        3,
        mps.in(Meters.Per(Seconds)),
    );
    try testing.expectApproxEqRel(
        @as(f128, 3.5),
        Meters.of(7.0).div(Seconds.of(2.0)).in(Meters.Per(Seconds)),
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
    try testing.expectEqual(b.as(f32).plus(c), c.plus(b.as(f32)));
    try testing.expectEqual(
        a.times(d).in(Meters.Of(Seconds)),
        d.times(a).in(Meters.Of(Seconds)),
    );
}

test "Runtime division" {
    const a = Radians.of(@as(i6, 20));
    const b = Newtons.of(@as(f16, 7));
    try testing.expectApproxEqRel(
        a.as(f16).div(b).in(Radians.Per(Newtons)),
        b.inv().times(a.as(f16)).in(Radians.Per(Newtons)),
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
    const val = Radians.of(10).as(f32);
    try testing.expectEqual(val.times(val), val.pow(2));

    const val2 = Watts.of(@as(f64, 17));
    try testing.expectEqual(val2.times(val2), val2.pow(2));
}

test "Units maintain identity and inverse properties of multiplication" {
    // there are, of course, absurdly large/precise values where this does not hold
    // in those cases, floating point arithmetic is likely not appropriate anyways
    const a = meters(1592287654567656789765787689878989876543234567654345678987654567345676543248472).div(Seconds.of(@as(f32, 2.123425))).times(Seconds.of(0.098765434569999999999997865435678654679999999999999978));
    try testing.expect(dim.Length.equals(@TypeOf(a).Unit.Dimension));
    try testing.expect(Meters.equals(@TypeOf(a).Unit));

    const b = radians(123456789).times(meters(@as(f32, 0.123456789654))).div(meters(34253));
    try testing.expect(dim.Angle.equals(@TypeOf(b).Unit.Dimension));
    try testing.expect(Radians.equals(@TypeOf(b).Unit));

    const c = radians(123456789).times(meters(@as(i32, 5)).as(f32)).div(meters(34253));
    try testing.expect(dim.Angle.equals(@TypeOf(c).Unit.Dimension));
    try testing.expect(Radians.equals(@TypeOf(c).Unit));
}
