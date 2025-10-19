const dim = @import("dimension.zig");
const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

// TODO should this be in base?
pub const Dimensionless = BaseQuantitySpec("one", dim.One);

const QuantityComponent = struct {
    Quantity: type,
    power: comptime_int,
};

pub const QuantityCharacter = enum {
    scalar, // TODO rename to real_scalar?
    complexScalar,
    vector,
    tensor,
};

// TODO maybe rename this to derivation?
const Equation = struct {
    components: []QuantityComponent,

    fn findComponentOfQuantity(self: Equation, OfQuantity: type) ?usize {
        for (self.components, 0..) |comp, i| {
            if (comp.Quantity == OfQuantity) return i;
        }
        return null;
    }

    // TODO sort output
    // TODO should we be excluding 0 values? probably not?
    // TODO this should allow for power=0 values, at least in some cases
    pub fn Times(self: Equation, RhsQuantity: type) Equation {
        // TODO could switch this to use TimesEqn under the hood
        if (self.findComponentOfQuantity(RhsQuantity)) |idx| {
            comptime var new_comps: [self.components.len]QuantityComponent = undefined;
            @memcpy(&new_comps, &self.components);
            new_comps[idx].power += 1;
            const num_new_comps = if (new_comps[idx].power == 0) blk: {
                for (new_comps[idx + 1 ..], idx..) |comp, i| {
                    new_comps[i] = comp;
                }
                break :blk new_comps.len - 1;
            } else new_comps.len;
            return Equation{ .components = new_comps[0..num_new_comps] };
        } else {
            comptime var new_comps: [self.components.len + 1]QuantityComponent = undefined;
            for (self.components, 0..) |comp, i| {
                if (mem.lessThan(u8, RhsQuantity.name, comp.Quantity.name)) {
                    new_comps[i] = self.components[i];
                } else {
                    new_comps[i] = QuantityComponent{ .power = 1, .Quantity = RhsQuantity };
                    @memcpy(new_comps[i + 1 ..], self.components[i..]);
                }
            }
            return Equation{ .components = new_comps };
        }
    }

    pub fn TimesEqn(self: Equation, Rhs: Equation) Equation {
        // assume equations are sorted
        comptime var l = 0;
        comptime var r = 0;
        comptime var numComps = 0;

        // count components
        while (l < self.components.len and r < Rhs.components.len) {
            if (self.components[l].Quantity == self.components[r].Quantity) {
                l += 1;
                r += 1;
            } else if (mem.lessThan(u8, self.components[l].Quantity.name, Rhs.components[r].Quantity.name)) {
                l += 1;
            } else {
                r += 1;
            }
            numComps += 1;
        }
        if (l == self.components.len) {
            numComps += self.components.len - l;
        } else if (r == Rhs.components.len) {
            numComps += Rhs.components.len - r;
        } else {
            @compileError(fmt.comptimePrint("Failed to multiple equations: {} and {}", .{ self, Rhs }));
        }

        // make new components
        comptime var comps: [numComps]QuantityComponent = undefined;
        l = 0;
        r = 0;
        comptime var i = 0;
        while (l < self.components.len and r < Rhs.components.len) {
            if (self.components[l].Quantity == self.components[r].Quantity) {
                comps[i] = QuantityComponent{
                    .Quantity = self.components[l].Quantity,
                    .power = self.components[l].power + Rhs.components[r].power,
                };
                l += 1;
                r += 1;
            } else if (mem.lessThan(u8, self.components[l].Quantity.name, Rhs.components[r].Quantity.name)) {
                comps[i] = self.components[l];
                l += 1;
            } else {
                comps[i] = self.components[r];
                r += 1;
            }
            i += 1;
        }
        if (l == self.components.len) {
            @memcpy(comps[i..], Rhs.components[r..]);
        } else if (r == Rhs.components.len) {
            @memcpy(comps[i..], self.components[l..]);
        } else {
            @compileError(fmt.comptimePrint("Failed to multiple equations: {} and {}", .{ self, Rhs }));
        }
    }

    pub fn Div(self: Equation, RhsQuantity: type) Equation {
        // TODO could switch this to use Inverse and TimesEqn
        if (self.findComponentOfQuantity(RhsQuantity)) |idx| {
            comptime var new_comps: [self.components.len]QuantityComponent = undefined;
            @memcpy(&new_comps, &self.components);
            new_comps[idx].power -= 1;
            const num_new_comps = if (new_comps[idx].power == 0) blk: {
                for (new_comps[idx + 1 ..], idx..) |comp, i| {
                    new_comps[i] = comp;
                }
                break :blk new_comps.len - 1;
            } else new_comps.len;
            return Equation{ .components = new_comps[0..num_new_comps] };
        } else {
            comptime var new_comps: [self.components.len + 1]QuantityComponent = undefined;
            for (self.components, 0..) |comp, i| {
                if (mem.lessThan(u8, RhsQuantity.name, comp.Quantity.name)) {
                    new_comps[i] = self.components[i];
                } else {
                    new_comps[i] = QuantityComponent{ .power = -1, .Quantity = RhsQuantity };
                    @memcpy(new_comps[i + 1 ..], self.components[i..]);
                }
            }
            return Equation{ .components = new_comps };
        }
    }

    pub fn DivEqn(self: Equation, Rhs: Equation) Equation {
        return self.Times(Rhs.Inverse());
    }

    pub fn Pow(self: Equation, n: comptime_int) Equation {
        comptime var comps: [self.components.len]QuantityComponent = undefined;
        for (self.components, 0..) |comp, i| {
            comps[i] = comp;
            comps[i].power *= n;
        }
        return comps;
    }

    pub fn Inverse(self: Equation) Equation {
        return self.Pow(-1);
    }

    pub fn Sqrt(self: Equation) Equation {
        return self.Pow(-2);
    }
};

pub const BaseEquation = Equation{ .components = .{} };

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub inline fn ChildQuantitySpec(name: []const u8, Parent: type) type {
    return QuantitySpec(name, Parent, Parent.equation, Parent.character);
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub inline fn ChildQuantitySpecWithEquation(name: []const u8, Parent: type, equation: Equation) type {
    // TODO validate equation
    return QuantitySpec(name, Parent, equation, Parent.character);
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from
pub inline fn ChildQuantitySpecOfCharacter(name: []const u8, Parent: type, character: QuantityCharacter) type {
    return QuantitySpec(name, Parent, Parent.equation, character);
}

/// Child quantity specs are those that are not root nodes in a quantity tree of a kind
///
/// The parent represents the node in the quantity hierarchy this quantity inherits from,
/// while the equation denotes the formulation of this quantity
pub inline fn ChildQuantitySpecWithEquationOfCharacter(name: []const u8, Parent: type, equation: Equation, character: QuantityCharacter) type {
    // TODO validate equation
    return QuantitySpec(name, Parent, equation, character);
}

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub inline fn DerivedQuantitySpec(name: []const u8, equation: Equation) type {
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

/// Derived quantity specs become root nodes in a new quantity tree/hierarchy of a kind
pub inline fn DerivedQuantitySpecOfCharacter(name: []const u8, equation: Equation, character: QuantityCharacter) type {
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

/// Base quantity specs are root nodes in a quantity tree/hierarchy, also known as "kinds"
pub inline fn BaseQuantitySpec(name: []const u8, BaseDimension: type) type {
    return QuantitySpec(name, BaseDimension, BaseEquation, QuantityCharacter.scalar);
}

/// The parent should be a Dimension or Quantity
///
/// Most quantities should be of scalar character
fn QuantitySpec(name_in: []const u8, ParentIn: type, equation_in: Equation, character_in: QuantityCharacter) type {
    // TODO validation that parent, equation, and character are valid
    const DimensionIn = if (ParentIn.isDimension()) ParentIn else ParentIn.Dimension;

    if (equation_in) |eq| {
        if (eq.len == 0) @compileError("Do not pass empty quantity component slice as equation");
        if (eq.len == 1) @compileError("A single quantity component is not a valid equation, use a child quantity instead");
        comptime var last = eq[0];
        for (eq) |comp| {
            if (mem.lessThan(u8, comp.Quantity.name, last.Quantity.name)) {
                @compileError("Do not pass unsorted quantity component slice as equantion");
            }
            last = comp;
        }
    }
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

        pub fn Pow(n: comptime_int) Equation {
            // @compileError(fmt.comptimePrint("{s}.Pow({d}): n must be >0", .{ @typeName(This), n }));
            return Equation{
                .components = .{QuantityComponent{ .power = n, .Quantity = This }},
            };
        }

        pub fn Inverse() Equation {
            return This.Pow(-1);
        }

        pub fn Sqrt() Equation {
            return This.Pow(-2);
        }

        pub fn Times(Rhs: type) Equation {
            return Pow(1).Times(Rhs);
        }

        pub fn TimesEqn(Rhs: Equation) Equation {
            return Pow(1).TimesEqn(Rhs);
        }

        pub fn Div(Rhs: type) Equation {
            return Pow(1).Div(Rhs);
        }

        pub fn DivEqn(Rhs: Equation) Equation {
            return Pow(1).DivEqn(Rhs);
        }
    };
}

/// this is used as a parameter type in mp-units to say you accept a kind of the quantity instead
/// of only a specific quantity
/// idk how to make that work in zig yet
pub const Kind = struct {
    QuantitySpec: type,
};

// TODO assert parents are sorted -- maybe this doesn't matter
// TODO make merging logic work right in terms of adding up powers of quantities
// pub fn Quantity(name_in: []const u8, DimensionIn: type, ParentsIn: []QuantityComponent) type {
//     return struct {
//         const Self = @This();
//         pub const Dimension = DimensionIn;
//         const Parents = ParentsIn;
//         const name = name_in;

//         pub fn Times(new_name: []const u8, OtherQuantity: type) type {
//             return Quantity(
//                 new_name,
//                 Dimension.MultipliedBy(OtherQuantity.Dimension),
//                 .{ Self, OtherQuantity }, // TODO sort
//             );
//         }

//         pub fn Pow(new_name: []const u8, power: comptime_int) type {
//             var Dim = dim.Dimensionless;
//             for (0..@abs(power)) |_| {
//                 Dim = Dim.MultipliedBy(Dimension);
//             }
//             if (power < 0) Dim = dim.Dimensionless.DividedBy(Dim);
//             return Quantity(new_name, Dim, .{ .Quantity = Self, .power = power });
//         }

//         pub fn Div(new_name: []const u8, OtherQuantity: type) type {
//             return Quantity(
//                 new_name,
//                 Dimension.DividedBy(OtherQuantity.Dimension),
//                 .{ .{ .Quantity = Self, .power = 1 }, .{ .Quantity = OtherQuantity, .power = -1 } }, // TODO sort
//             );
//         }

//         pub fn Inverse(new_name: []const u8) type {
//             return Pow(new_name, -1);
//         }

//         pub fn Child(new_name: []const u8) type {
//             return Quantity(new_name, Dimension, .{.{ .Quantity = Self, .power = 1 }});
//         }
//     };
// }

// pub fn BaseQuantity(name: []const u8, BaseDimensionIn: type) type {
//     return Quantity(name, BaseDimensionIn, .{});
// }

// pub fn Compose(new_name: []const u8, Quantities: []QuantityComponent) type {
//     var Dim = dim.DimensionOne;
//     for (Quantities) |Q| {
//         if (Q.power < 0) {
//             for (0..@abs(Q.power)) |_| {
//                 Dim = Dim.DividedBy(Q.Dimension);
//             }
//         } else if (Q.power > 0) {
//             for (0..Q.power) |_| {
//                 Dim = Dim.MultipliedBy(Q.Dimension);
//             }
//         }
//     }
//     return Quantity(
//         new_name,
//         Dim,
//         Quantities, // TODO sort
//     );
// }

// When we say hierarchy, we mean hierarchy tree of quantities of the same kind, but that's a mouth (hand?) full
// All quantities have a character, e.g. scalar, vector, tensor. Scalar is the default
// Base Quantity - quantity from a dimension, creates a new hierarchy
// Child Quantity - quantity as a child node of another quantity in the hierarchy
// Derived Quantity - quantity derived from a combination of other quantities, creates a new hierarchy
// Child Derived Quantity - quantity as a child node of another quantity in the hierarchy derived from a combination of other quantities
//

// maybe let users add custom semantics to quantities themselves? or provide specializations of units that are functionally identical but provide an additional layer of semantic verification (or at least printing)
