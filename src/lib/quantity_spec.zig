const dim = @import("dimension.zig");
const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const eqn = @import("equation.zig");
const util = @import("util.zig");

pub const QuantityCharacter = enum {
    scalar, // TODO rename to real_scalar?
    complexScalar,
    vector,
    tensor,
};

fn validateNonBaseParent(Parent: type) void {
    if (!@hasDecl(Parent, "isDimension") or Parent.isDimension()) @compileError("Parent of non-base `QuantitySpec` must be a `QuantitySpec`");
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub fn ChildQuantitySpec(name: []const u8, Parent: type) type {
    validateNonBaseParent(Parent);
    return QuantitySpec(name, Parent, Parent.equation, Parent.character);
}

test ChildQuantitySpec {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const Test = ChildQuantitySpec("example child", TestBase);
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(TestBase, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try eqn.Equation.expectEqual(eqn.one, Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child");
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub fn ChildQuantitySpecWithEquation(name: []const u8, Parent: type, equation: eqn.Equation) type {
    validateNonBaseParent(Parent);
    return QuantitySpec(name, Parent, equation, Parent.character);
}

test ChildQuantitySpecWithEquation {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const TestBaseSquared = DerivedQuantitySpec("example quantity spec squared", TestBase.times(TestBase));
    const Test = ChildQuantitySpecWithEquation("example child with eqn", TestBase, TestBaseSquared.equation.div(TestBase));
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(TestBase, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try eqn.Equation.expectEqual(eqn.one.times(TestBase), Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child with eqn");
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub fn ChildQuantitySpecOfCharacter(name: []const u8, Parent: type, character: QuantityCharacter) type {
    validateNonBaseParent(Parent);
    return QuantitySpec(name, Parent, Parent.equation, character);
}

test ChildQuantitySpecOfCharacter {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const Test = ChildQuantitySpecOfCharacter("example child with char", TestBase, QuantityCharacter.complexScalar);
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(TestBase, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.complexScalar);
    try eqn.Equation.expectEqual(eqn.one, Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child with char");
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub inline fn ChildQuantitySpecWithEquationOfCharacter(name: []const u8, Parent: type, equation: eqn.Equation, character: QuantityCharacter) type {
    validateNonBaseParent(Parent);
    return QuantitySpec(name, Parent, equation, character);
}

test ChildQuantitySpecWithEquationOfCharacter {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const TestBaseSquared = DerivedQuantitySpec("example quantity spec squared", TestBase.times(TestBase));
    const Test = ChildQuantitySpecWithEquationOfCharacter(
        "example child with eqn",
        TestBase,
        TestBaseSquared.equation.div(TestBase),
        QuantityCharacter.vector,
    );
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(TestBase, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.vector);
    try eqn.Equation.expectEqual(eqn.one, Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child with eqn");
}

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub fn DerivedQuantitySpec(name: []const u8, equation: eqn.Equation) type {
    comptime var Dimension = dim.One;
    inline for (equation.components) |comp| {
        if (comp.power >= 0) {
            for (0..comp.power) |_| {
                Dimension = Dimension.MultipliedBy(comp.Type.Dimension);
            }
        } else {
            for (0..@abs(comp.power)) |_| {
                Dimension = Dimension.DividedBy(comp.Type.Dimension);
            }
        }
    }
    return QuantitySpec(name, Dimension, equation, QuantityCharacter.scalar);
}

test DerivedQuantitySpec {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const Test = DerivedQuantitySpec("example child", TestBase.div(TestBase));
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(dim.One, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try eqn.Equation.expectEqual(eqn.one.times(TestBase).pow(0), Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child");
}

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub fn DerivedQuantitySpecOfCharacter(name: []const u8, equation: eqn.Equation, character: QuantityCharacter) type {
    comptime var Dimension = dim.One;
    inline for (equation.components) |comp| {
        if (comp.power >= 0) {
            for (0..comp.power) |_| {
                Dimension = Dimension.MultipliedBy(comp.Type.Dimension);
            }
        } else {
            for (0..@abs(comp.power)) |_| {
                Dimension = Dimension.DividedBy(comp.Type.Dimension);
            }
        }
    }
    return QuantitySpec(name, Dimension, equation, character);
}

test DerivedQuantitySpecOfCharacter {
    const ExampleDimension = dim.BaseDimension('E');
    const TestBase = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const Test = DerivedQuantitySpec("example child", TestBase.div(TestBase));
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(dim.One, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try eqn.Equation.expectEqual(eqn.one.times(TestBase).pow(0), Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example child");
}

/// Base quantity specs are root nodes in a quantity tree/hierarchy, also known as "kinds"
pub inline fn BaseQuantitySpec(name: []const u8, BaseDimension: type) type {
    if (!@hasDecl(BaseDimension, "isDimension") or !BaseDimension.isDimension()) @compileError("Parent of base `QuantitySpec` must be a `Dimension`");
    return QuantitySpec(name, BaseDimension, eqn.one, QuantityCharacter.scalar);
}

test BaseQuantitySpec {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try std.testing.expect(!Test.isDimension());
    try std.testing.expectEqual(ExampleDimension, Test.Parent);
    try std.testing.expectEqual(Test.character, QuantityCharacter.scalar);
    try eqn.Equation.expectEqual(eqn.one, Test.equation);
    try std.testing.expectEqualStrings(Test.name, "example quantity spec");
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

test "QuantitySpec.isDimension" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try std.testing.expect(!Test.isDimension());
}

test "QuantitySpec.pow" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(3), Test.pow(3));
}

test "QuantitySpec.inverse" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(-1), Test.inverse());
}

test "QuantitySpec.sqrt" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(-2), Test.sqrt());
}

test "QuantitySpec.times" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(2), Test.times(Test));
}

test "QuantitySpec.timesEqn" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(2), Test.timesEqn(Test.pow(1)));
}

test "QuantitySpec.div" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(0), Test.div(Test));
}

test "QuantitySpec.divEqn" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    try eqn.Equation.expectEqual(eqn.one.times(Test).pow(0), Test.divEqn(Test.pow(1)));
}

test "QuantitySpec multiplication doesn't compose their derivations" {
    const ExampleDimension = dim.BaseDimension('E');
    const Test = BaseQuantitySpec("example quantity spec", ExampleDimension);
    const Test2 = DerivedQuantitySpec("example quantity spec 2", Test.pow(1));
    try eqn.Equation.expectEqual(eqn.one.times(Test2).pow(2), Test2.times(Test2));
}
