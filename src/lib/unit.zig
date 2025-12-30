const std = @import("std");
const dim = @import("dimension.zig");
const q = @import("quantity.zig");
const qs = @import("quantity_spec.zig");
const qp = @import("quantity_point.zig");
const eqn = @import("equation.zig");

/// this is used as a parameter type in mp-units to say you accept a kind of the quantity instead
/// of only a specific quantity
/// idk how to make that work in zig yet
const KindContainer = struct {
    QuantitySpec: type,
};

pub fn KindOf(QuantitySpec: type) KindContainer {
    if (!QuantitySpec.Parent.isDimension()) {
        @compileError(
            std.fmt.comptimePrint(
                \\Tried to create kind of quantity spec which is not a root of a hierarchy, ensure 
                \\KindOf() is called with a quantity spec whose parent is a dimension, not another 
                \\quantity spec: {s}
            , .{QuantitySpec.name}),
        );
    }
    return KindContainer{
        .QuantitySpec = QuantitySpec,
    };
}

pub const One = Named("", "", KindContainer(qs.Dimensionless));

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
const one = Ratio{ .numerator = 1, .denominator = 1 };

const Derivation = union {
    equation: eqn.Equation,
    kind: KindContainer,
};

fn Unit(
    name_in: []const u8,
    symbol_in: []const u8,
    KindIn: ?KindContainer,
    multiplier_in: Ratio,
    equation_in: ?eqn.Equation,
    OriginIn: ?qp.AbsolutePointOriginContainer,
) type {
    // TODO validate equation's dimension matches kind
    return struct {
        const This = @This();

        /// the full name of the unit
        pub const name = name_in;

        /// the abbreviated name of the unit
        pub const symbol = symbol_in;

        /// the kind of the unit defines which tree of quantities can be represented by this unit
        /// see `Kind` in `quantity_spec.zig`
        pub const Kind = KindIn;

        /// Represents the factor that the equation is multiplied by. For
        /// not scaled units, this will simply be 1
        pub const multiplier = multiplier_in;

        /// Represents the derivation of this unit from base units
        ///
        /// Will be null for base units, as a base unit's derivation
        /// is just itself
        pub const equation = equation_in orelse eqn.one.times(This);

        /// Optional global origin point for this unit. This should
        /// only be used for units that represent absolute quantities,
        /// such as temperature
        pub const Origin = OriginIn;

        /// Represents an offset from a base unit. Useful for units
        /// such as fahrenheit.
        ///
        /// TODO couldn't only units with an Origin have an offset?
        /// like the offset is only relevant because there's an
        /// absolute origin, so maybe there's someway to tie those together
        /// neatly
        // pub const offset = offset_in;

        /// Get a ratio representing `x` of this unit.
        ///
        /// e.g. for a base unit of `Seconds`, `Minutes` has a ratio of 1/60,
        /// therefore `Minutes.Times(60)` would produce a ratio of 1/3600 since
        /// that would scale 1 `Hour` to the equivalent quantity of seconds
        pub fn times(x: comptime_int) Ratio {
            return multiplier.div(x);
        }

        /// We want to be able to derive other units by multiplying and dividing units together
        /// without having to explicitly name them
        ///
        /// therefore naming a unit must be optional, and so we must construct a somewhat meaningful
        /// representation of the unit absent a provided name
        ///
        /// we also want named and unnamed units of the same derivation to be considered equivalent,
        /// meaning we need to be able to draw this equivalency somehow based on the actual derivation
        /// of the unit, but what specifically?
        ///
        /// certainly equivalent units would be part of the same quantity hierarchy, i.e. of the same kind,
        /// but that likely isn't enough
        ///
        /// we wouldn't expect seconds to "equal" microseconds, e.g.
        ///
        /// therefore the ratio must also be taken into account
        ///
        /// but a ratio is only meaningful relative to it's base
        ///
        /// we might expect there to be parallel measurement systems though, potentially, and so
        /// we must also consider the actual derivation of the unit, the "equation" if you will,
        /// but this equation must be simplified in a deterministic way such that any process which produces
        /// mathematically equivalent units produces identical equations on the corresponding unit type
        ///
        /// unlike quantities, we actually want to consider the derivation in it's entirety, not just the
        /// derivation in relation to the immediately dependent parts, e.g. we want an equation of
        /// microseconds / kilograms to appear the same as seconds / gram
        ///
        /// mp-units apparently handles this problem by separating the scaled and derived units
        /// and ensuring derived units are only constructed from base units, then scaled appropriately
        ///
        /// therefore scaled unit is always some base unit and a scale factor, and derived unit is
        /// always some combination of base units, and either scaled or derived units can be named
        ///
        /// therefore by having an equation of base units and a multiplier, we essentially solve the
        /// problem, as we can check equality by ensuring multipliers are always least common factors and
        /// unit equations are always composed of base units
        ///
        /// a base unit can be defined as a unit whose multiplier is one, and whose equation is null
        ///
        /// i should rename the equation to "derivation" here
        ///
        /// TODO consider the following from mp-units
        /// The new syntax simplifies API as one `quantity` class template will now serve all quantity
        /// variations (possibly even more in the future). It also allows us to model quantities that
        /// were impossible to express before without some workarounds.
        ///
        /// For example, we can now correctly calculate Carnot engine efficiency with any of the following:
        ///
        /// ```cpp
        /// quantity temp_cold = 300. * K;
        /// quantity temp_hot = 500. * K;
        /// quantity carnot_eff_1 = 1. - temp_cold / temp_hot;
        /// quantity carnot_eff_2 = (temp_hot - temp_cold) / temp_hot;
        /// ```
        ///
        /// we want to be able to do this, basically, and I'm not sure how we can exactly
        pub fn Times(RhsUnit: type) type {
            // TODO does this work?
            if (Origin || RhsUnit.Origin) {
                // TODO maybe figure out better way to handle this,
                // not sure if there are any units that need a unit
                // with an origin as a component
                @compileError(std.fmt.comptimePrint("Error attempting to multiple units \"{s}\" and \"{s}\": Cannot multiply units with absolute point origins", .{ name, RhsUnit.name }));
            }

            // if rhs == one return lhs
            // if lhs == one return rhs
            // if is_specialization_of<Lhs, To> && is_specialization_of<Rhs, To>
            // is_specialization_of<Lhs, To>
            // is_specialization_of<Rhs, To>
            // else

            // combine equations
            return Unit(
                name ++ "*" ++ RhsUnit.name,
                symbol ++ "*" ++ RhsUnit.name,
                // is this necessary?
                // what would we need to check this for?
                Kind.Times(RhsUnit.Kind),
                multiplier.times(RhsUnit.multiplier),
                equation.TimesEqn(RhsUnit.equation),
                null,
            );
        }

        pub fn of(value: anytype) q.Quantity(Kind.QuantitySpec, @TypeOf(value)) {
            return .{ .value = value };
        }
    };
}

pub fn Named(name: []const u8, symbol: []const u8, Kind: KindContainer) type {
    return Unit(name, symbol, Kind, one, null, null);
}

pub fn NamedWithOrigin(name: []const u8, symbol: []const u8, Kind: KindContainer, Origin: qs.AbsolutePointOriginContainer) type {
    return Unit(name, symbol, Kind, one, null, Origin);
}

pub fn NamedWithEquation(name: []const u8, symbol: []const u8, equation: eqn.Equation, Kind: KindContainer) type {
    return Unit(name, symbol, Kind, one, equation, null);
}

// pub fn NamedWithEquation(name: []const u8, symbol: []const u8, )

pub fn Kilo(OfUnit: type) type {
    return Unit(
        "kilo" ++ OfUnit.name,
        "k" ++ OfUnit.symbol,
        OfUnit.Kind,
        OfUnit.times(1000),
    );
}
