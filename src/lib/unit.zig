const dim = @import("dimension.zig");
const q = @import("quantity.zig");
const qs = @import("quantity_spec.zig");

pub const One = BaseUnit("", "", qs.Kind(qs.Dimensionless));

/// way to describe how a unit of the same kind relates to another, for example an
/// hour could be defined with Minute.Times(60), meaning an hour is
/// 60 minutes. Hence the ratio multiplier represents the multiplier to convert from the
/// unit being defined to the unit the multiplier was derived from
const Ratio = struct {
    numerator: comptime_int,
    denominator: comptime_int,

    // TODO add checks and make safe n shit
    pub fn times(self: Ratio, rhs: Ratio) Ratio {
        // TODO gcd
        return .{
            .numerator = self.numerator * rhs.numerator,
            .denominator = self.denominator * rhs.denominator,
        };
    }

    pub fn div(self: Ratio, rhs: Ratio) Ratio {
        return .{
            .numerator = self.numerator * rhs.denominator,
            .denominator = self.denominator * rhs.numerator,
        };
    }
};

pub inline fn BaseUnit(name: []const u8, symbol: []const u8, Kind: type) type {
    return Unit(name, symbol, Kind, Ratio{ .numerator = 1, .denominator = 1 });
}

fn Unit(name_in: []const u8, symbol_in: []const u8, KindIn: qs.Kind, multiplier_in: Ratio) type {
    return struct {
        /// the full name of the unit
        pub const name = name_in;

        /// the abbreviated name of the unit
        pub const symbol = symbol_in;

        /// the kind of the unit defines which tree of quantities can be represented by this unit
        /// see `Kind` in `quantity_spec.zig`
        pub const Kind = KindIn;

        /// Multiplying a quantity of this unit by the multiplier produces a quantity of the base unit
        pub const multiplier = multiplier_in;

        /// Get a ratio representing `x` of this unit.
        ///
        /// e.g. for a base unit of `Seconds`, `Minutes` has a ratio of 1/60,
        /// therefore `Minutes.Times(60)` would produce a ratio of 1/3600 since
        /// that would scale 1 `Hour` to the equivalent quantity of seconds
        pub fn Times(x: comptime_int) Ratio {
            return multiplier.div(x);
        }

        pub fn of(value: anytype) q.Quantity(Kind.QuantitySpec, @TypeOf(value)) {
            return .{ .value = value };
        }
    };
}

pub fn Kilo(OfUnit: type) type {
    return Unit(
        OfUnit.name,
        OfUnit.symbol,
        OfUnit.Kind,
        OfUnit.times(1000),
    );
}
