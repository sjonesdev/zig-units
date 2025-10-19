const dim = @import("lib/dimension.zig");
const quantity = @import("quantity.zig");

// could define a list of special unit names and otherwise rely on dynamic unit representation creation?
// that wouldn't be extensible though

/// DimensionIn - dimension of unit
/// name_in - display name of unit
/// abbreviation_in - display abbreviation of unit
/// multiplier_in - the value the unit must be multiplied by to convert to it's base unit
/// offset_in - the value that must be added to the unit (after being multiplied) to convert to it's base unit
pub fn Unit(DimensionIn: type, name_in: []const u8, abbreviation_in: []const u8, multiplier_in: comptime_float, offset_in: comptime_float) type {
    return struct {
        const Self = @This();
        pub const Dimension = DimensionIn;
        pub const name = name_in;
        pub const abbreviation = abbreviation_in;
        pub const multiplier: comptime_float = multiplier_in;
        pub const offset: comptime_float = offset_in;

        /// scale_factor refers to the value you must multiply
        /// the current unit by to get a value in the new unit.
        /// That is, the amount of the new unit that is one of the
        /// current unit
        pub fn ScaledTo(unit_name: []const u8, unit_abbreviation: []const u8, scale_factor: comptime_float) type {
            return Unit(
                Self.Dimension,
                unit_name,
                unit_abbreviation,
                scale_factor * multiplier,
                scale_factor * offset,
            );
        }

        /// offset_value refers to the value you must add to the
        /// current unit to get a value in the new unit. That is, the
        /// value of the new unit equal to 0 of the old unit.
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

        /// Makes a version of this unit with a different
        /// display name and abbreviation
        pub fn Named(new_name: []const u8, new_abbreviation: []const u8) type {
            return Unit(
                Self.Dimension,
                new_name,
                new_abbreviation,
                multiplier,
                offset,
            );
        }

        /// Makes a version of this unit with a different display abbreviation
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

        /// Make a quantity of this unit with the underlying type
        /// as that of the value passed
        pub inline fn of(value: anytype) quantity.Quantity(Self, @TypeOf(value)) {
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

/// Unit identity
pub const Unitless = BaseUnit(dim.One, "unitless", "u");
