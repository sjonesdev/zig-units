const dim = @import("dimension.zig");
const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const eqn = @import("equation.zig");

// TODO should this be in base?
pub const Dimensionless = BaseQuantitySpec("one", dim.One);

pub const QuantityCharacter = enum {
    scalar, // TODO rename to real_scalar?
    complexScalar,
    vector,
    tensor,
};

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub inline fn ChildQuantitySpec(name: []const u8, Parent: type) type {
    return QuantitySpec(name, Parent, Parent.equation, Parent.character);
}

test ChildQuantitySpec {}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub inline fn ChildQuantitySpecWithEquation(name: []const u8, Parent: type, equation: eqn.Equation) type {
    // TODO validate equation
    return QuantitySpec(name, Parent, equation, Parent.character);
}

test ChildQuantitySpecWithEquation {}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub inline fn ChildQuantitySpecOfCharacter(name: []const u8, Parent: type, character: QuantityCharacter) type {
    return QuantitySpec(name, Parent, Parent.equation, character);
}

test ChildQuantitySpecOfCharacter {}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub inline fn ChildQuantitySpecWithEquationOfCharacter(name: []const u8, Parent: type, equation: eqn.Equation, character: QuantityCharacter) type {
    // TODO validate equation
    return QuantitySpec(name, Parent, equation, character);
}

test ChildQuantitySpecWithEquationOfCharacter {}

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub inline fn DerivedQuantitySpec(name: []const u8, equation: eqn.Equation) type {
    comptime var Dimension = dim.One;
    for (equation) |comp| {
        if (comp.power > 0) {
            for (0..comp.power) |_| {
                Dimension = Dimension.MultipliedBy(comp.Quantity.Dimension);
            }
        } else {
            for (0..@abs(comp.power)) |_| {
                Dimension = Dimension.DividedBy(comp.Quantity.Dimension);
            }
        }
    }
    // TODO quantity character
    return QuantitySpec(name, Dimension, equation);
}

test DerivedQuantitySpec {}

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub inline fn DerivedQuantitySpecOfCharacter(name: []const u8, equation: eqn.Equation, character: QuantityCharacter) type {
    comptime var Dimension = dim.One;
    for (equation) |comp| {
        if (comp.power > 0) {
            for (0..comp.power) |_| {
                Dimension = Dimension.MultipliedBy(comp.Quantity.Dimension);
            }
        } else {
            for (0..@abs(comp.power)) |_| {
                Dimension = Dimension.DividedBy(comp.Quantity.Dimension);
            }
        }
    }
    return QuantitySpec(name, Dimension, equation, character);
}

test DerivedQuantitySpecOfCharacter {}

/// Base quantity specs are root nodes in a quantity tree/hierarchy, also known as "kinds"
pub inline fn BaseQuantitySpec(name: []const u8, BaseDimension: type) type {
    return QuantitySpec(name, BaseDimension, eqn.one, QuantityCharacter.scalar);
}

test BaseQuantitySpec {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try std.testing.expect(!Test.isDimension());
    try std.testing.expect(Test.Parent.isDimension());
    try std.testing.expect(Test.Parent.isBase());
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try std.testing.expectEqual(Test.equation, eqn.one);
}

/// The parent should be a Dimension or Quantity
///
/// Most quantities should be of scalar character
fn QuantitySpec(name_in: []const u8, ParentIn: type, equation_in: eqn.Equation, character_in: QuantityCharacter) type {
    // TODO validation that parent, equation, and character are valid
    const DimensionIn = if (ParentIn.isDimension()) ParentIn else ParentIn.Dimension;

    return struct {
        const This = @This();
        // using @typeName won't work because it uses the name of the function (quantity spec), but
        // maybe we could crawl declaration lists to get the name of the type?
        // not sure how you could support user definitions with that though
        pub const name = name_in;
        pub const Parent = ParentIn;
        pub const Dimension = DimensionIn;
        pub const equation = equation_in;
        pub const character = character_in;

        pub inline fn isDimension() bool {
            return false;
        }

        pub fn pow(n: comptime_int) eqn.Equation {
            return eqn.one.times(This).pow(n);
        }

        pub fn inverse() eqn.Equation {
            return This.pow(-1);
        }

        pub fn sqrt() eqn.Equation {
            return This.pow(-2);
        }

        pub fn times(Rhs: type) eqn.Equation {
            return pow(1).times(Rhs);
        }

        pub fn timesEqn(rhs: eqn.Equation) eqn.Equation {
            return pow(1).timesEqn(rhs);
        }

        pub fn div(Rhs: type) eqn.Equation {
            return pow(1).div(Rhs);
        }

        pub fn divEqn(rhs: eqn.Equation) eqn.Equation {
            return pow(1).divEqn(rhs);
        }
    };
}

test "QuantitySpec multiplication doesn't compose their derivations" {}

test "QuantitySpec.isDimension" {}

test "QuantitySpec.pow" {}

test "QuantitySpec.inverse" {}

test "QuantitySpec.sqrt" {}

test "QuantitySpec.times" {}

test "QuantitySpec.timesEqn" {}

test "QuantitySpec.div" {}

test "QuantitySpec.divEqn" {}

// When we say hierarchy, we mean hierarchy tree of quantities of the same kind, but that's a mouth (hand?) full
// All quantities have a character, e.g. scalar, vector, tensor. Scalar is the default
// Base Quantity - quantity from a dimension, creates a new hierarchy
// Child Quantity - quantity as a child node of another quantity in the hierarchy
// Derived Quantity - quantity derived from a combination of other quantities, creates a new hierarchy
// Child Derived Quantity - quantity as a child node of another quantity in the hierarchy derived from a combination of other quantities
//

// maybe let users add custom semantics to quantities themselves? or provide specializations of units that are functionally identical but provide an additional layer of semantic verification (or at least printing)
