const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const util = @import("util.zig");

const Component = struct {
    Type: type,
    power: comptime_int,

    fn str(self: Component) []const u8 {
        const pow_str = std.fmt.comptimePrint("{d}", .{self.power});
        const name = if (@hasDecl(self.Type, "name"))
            self.Type.name
        else
            @typeName(self.Type);
        return name ++ "^" ++ pow_str;
    }

    fn lessThan(_: anytype, lhs: Component, rhs: Component) bool {
        return mem.lessThan(u8, @typeName(lhs.Type), @typeName(rhs.Type));
    }
};

const Equation = struct {
    components: []const Component,

    fn of(Type: type) Equation {
        return Equation{
            .components = &[_]Component{
                Component{
                    .power = 1,
                    .Type = Type,
                },
            },
        };
    }

    pub fn timesEqn(self: Equation, rhs: Equation) Equation {
        // assume equations are sorted
        comptime var l = 0;
        comptime var r = 0;
        comptime var numComps = 0;

        // count components
        while (l < self.components.len and r < rhs.components.len) {
            if (self.components[l].Type == rhs.components[r].Type) {
                l += 1;
                r += 1;
            } else if (mem.lessThan(u8, @typeName(self.components[l].Type), @typeName(rhs.components[r].Type))) {
                l += 1;
            } else {
                r += 1;
            }
            numComps += 1;
        }
        if (l == self.components.len) {
            numComps += rhs.components.len - r;
        } else if (r == rhs.components.len) {
            numComps += self.components.len - l;
        } else {
            @compileError(fmt.comptimePrint("Failed to multiply equations: {} and {}", .{ self, rhs }));
        }

        // make new components
        comptime var comps: [numComps]Component = undefined;
        l = 0;
        r = 0;
        comptime var i = 0;
        while (l < self.components.len and r < rhs.components.len) {
            if (self.components[l].Type == rhs.components[r].Type) {
                comps[i] = Component{
                    .Type = self.components[l].Type,
                    .power = self.components[l].power + rhs.components[r].power,
                };
                l += 1;
                r += 1;
            } else if (mem.lessThan(u8, @typeName(self.components[l].Type), @typeName(rhs.components[r].Type))) {
                comps[i] = self.components[l];
                l += 1;
            } else {
                comps[i] = rhs.components[r];
                r += 1;
            }
            i += 1;
        }
        if (l == self.components.len) {
            for (rhs.components[r..], i..) |comp, idx| {
                comps[idx] = comp;
            }
        } else if (r == rhs.components.len) {
            for (self.components[l..], i..) |comp, idx| {
                comps[idx] = comp;
            }
        } else {
            @compileError(fmt.comptimePrint("Failed to multiply equations: {any} and {any}", .{ self, rhs }));
        }

        const comps_final: [numComps]Component = comps;
        return Equation{ .components = &comps_final };
    }

    pub fn divEqn(self: Equation, rhs: Equation) Equation {
        return self.timesEqn(rhs.inverse());
    }

    pub fn times(self: Equation, Type: type) Equation {
        return self.timesEqn(Equation.of(Type));
    }

    pub fn div(self: Equation, Type: type) Equation {
        return self.timesEqn(Equation.of(Type).inverse());
    }

    pub fn pow(self: Equation, n: comptime_int) Equation {
        comptime var comps: [self.components.len]Component = undefined;
        for (self.components, 0..) |comp, i| {
            comps[i] = comp;
            comps[i].power *= n;
        }
        const comps_final = comps;
        return Equation{ .components = &comps_final };
    }

    pub fn inverse(self: Equation) Equation {
        return self.pow(-1);
    }

    pub fn sqrt(self: Equation) Equation {
        return self.pow(-2);
    }

    pub fn fullStr(self: Equation) []const u8 {
        if (self.components.len == 0) return "";
        comptime var eqn_str: []const u8 = self.components[0].str();
        comptime for (self.components[1..]) |comp| {
            eqn_str = eqn_str ++ " * " ++ comp.str();
        };
        const eqn_str_const = eqn_str;
        return eqn_str_const;
    }
};

pub const one = Equation{ .components = .{} };

test "Equation.TimesEqn" {
    const Type1 = struct {};
    const Type2 = struct {};
    const Type3 = struct {};
    const Type4 = struct {};
    const Type5 = struct {};

    const eqn1 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = 2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type5, .power = 0 },
    } };
    const eqn2 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = -2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type4, .power = 1 },
    } };

    const eqn3 = eqn1.timesEqn(eqn2);
    const expected_eqn3 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = 0 },
            .{ .Type = Type2, .power = -4 },
            .{ .Type = Type3, .power = 6 },
            .{ .Type = Type4, .power = 1 },
            .{ .Type = Type5, .power = 0 },
        },
    };
    const expected_eqn3_str = util.filterNewlines(
        \\equation.test.Equation.TimesEqn.Type1^0 * 
        \\equation.test.Equation.TimesEqn.Type2^-4 * 
        \\equation.test.Equation.TimesEqn.Type3^6 * 
        \\equation.test.Equation.TimesEqn.Type4^1 * 
        \\equation.test.Equation.TimesEqn.Type5^0
    );

    try std.testing.expectEqualStrings(expected_eqn3.fullStr(), eqn3.fullStr());
    try std.testing.expectEqualStrings(expected_eqn3_str, eqn3.fullStr());
}

test "Equation.DivEqn" {
    const Type1 = struct {};
    const Type2 = struct {};
    const Type3 = struct {};
    const Type4 = struct {};
    const Type5 = struct {};
    const Type6 = struct {};

    const eqn1 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = 2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type5, .power = 0 },
    } };
    const eqn2 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = -2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type4, .power = 1 },
        .{ .Type = Type6, .power = 10 },
    } };

    const eqn3 = eqn1.divEqn(eqn2);
    const expected_eqn3 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = 4 },
            .{ .Type = Type2, .power = 0 },
            .{ .Type = Type3, .power = 0 },
            .{ .Type = Type4, .power = -1 },
            .{ .Type = Type5, .power = 0 },
            .{ .Type = Type6, .power = -10 },
        },
    };
    const expected_eqn3_str = util.filterNewlines(
        \\equation.test.Equation.DivEqn.Type1^4 * 
        \\equation.test.Equation.DivEqn.Type2^0 * 
        \\equation.test.Equation.DivEqn.Type3^0 * 
        \\equation.test.Equation.DivEqn.Type4^-1 * 
        \\equation.test.Equation.DivEqn.Type5^0 * 
        \\equation.test.Equation.DivEqn.Type6^-10
    );

    try std.testing.expectEqualStrings(expected_eqn3.fullStr(), eqn3.fullStr());
    try std.testing.expectEqualStrings(expected_eqn3_str, eqn3.fullStr());
}

test "Equation.Times" {
    const Type1 = struct {};
    const Type2 = struct {};
    const Type3 = struct {};
    const Type4 = struct {};
    const Type5 = struct {};

    const eqn1 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = 2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type5, .power = 0 },
    } };

    const eqn3 = eqn1.times(Type4);
    const expected_eqn3 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = 2 },
            .{ .Type = Type2, .power = -2 },
            .{ .Type = Type3, .power = 3 },
            .{ .Type = Type4, .power = 1 },
            .{ .Type = Type5, .power = 0 },
        },
    };
    const expected_eqn3_str = util.filterNewlines(
        \\equation.test.Equation.Times.Type1^2 * 
        \\equation.test.Equation.Times.Type2^-2 * 
        \\equation.test.Equation.Times.Type3^3 * 
        \\equation.test.Equation.Times.Type4^1 * 
        \\equation.test.Equation.Times.Type5^0
    );

    try std.testing.expectEqualStrings(expected_eqn3.fullStr(), eqn3.fullStr());
    try std.testing.expectEqualStrings(expected_eqn3_str, eqn3.fullStr());
}

test "Equation.Div" {
    const Type1 = struct {};
    const Type2 = struct {};
    const Type3 = struct {};
    const Type4 = struct {};
    const Type5 = struct {};

    const eqn1 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = 2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type5, .power = 0 },
    } };

    const eqn3 = eqn1.div(Type4);
    const expected_eqn3 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = 2 },
            .{ .Type = Type2, .power = -2 },
            .{ .Type = Type3, .power = 3 },
            .{ .Type = Type4, .power = -1 },
            .{ .Type = Type5, .power = 0 },
        },
    };
    const expected_eqn3_str = util.filterNewlines(
        \\equation.test.Equation.Div.Type1^2 * 
        \\equation.test.Equation.Div.Type2^-2 * 
        \\equation.test.Equation.Div.Type3^3 * 
        \\equation.test.Equation.Div.Type4^-1 * 
        \\equation.test.Equation.Div.Type5^0
    );

    try std.testing.expectEqualStrings(expected_eqn3.fullStr(), eqn3.fullStr());
    try std.testing.expectEqualStrings(expected_eqn3_str, eqn3.fullStr());
}

test "Equation.Pow" {
    const Type1 = struct {};
    const Type2 = struct {};
    const Type3 = struct {};
    const Type4 = struct {};

    const eqn1 = Equation{ .components = &[_]Component{
        .{ .Type = Type1, .power = 2 },
        .{ .Type = Type2, .power = -2 },
        .{ .Type = Type3, .power = 3 },
        .{ .Type = Type4, .power = 0 },
    } };

    const eqn2 = eqn1.pow(-4);
    const expected_eqn2 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = -8 },
            .{ .Type = Type2, .power = 8 },
            .{ .Type = Type3, .power = -12 },
            .{ .Type = Type4, .power = 0 },
        },
    };
    const expected_eqn2_str = util.filterNewlines(
        \\equation.test.Equation.Pow.Type1^-8 * 
        \\equation.test.Equation.Pow.Type2^8 * 
        \\equation.test.Equation.Pow.Type3^-12 * 
        \\equation.test.Equation.Pow.Type4^0
    );

    try std.testing.expectEqualStrings(expected_eqn2.fullStr(), eqn2.fullStr());
    try std.testing.expectEqualStrings(expected_eqn2_str, eqn2.fullStr());

    const eqn3 = eqn1.pow(3);
    const expected_eqn3 = Equation{
        .components = &[_]Component{
            .{ .Type = Type1, .power = 6 },
            .{ .Type = Type2, .power = -6 },
            .{ .Type = Type3, .power = 9 },
            .{ .Type = Type4, .power = 0 },
        },
    };
    const expected_eqn3_str = util.filterNewlines(
        \\equation.test.Equation.Pow.Type1^6 * 
        \\equation.test.Equation.Pow.Type2^-6 * 
        \\equation.test.Equation.Pow.Type3^9 * 
        \\equation.test.Equation.Pow.Type4^0
    );

    try std.testing.expectEqualStrings(expected_eqn3.fullStr(), eqn3.fullStr());
    try std.testing.expectEqualStrings(expected_eqn3_str, eqn3.fullStr());
}
