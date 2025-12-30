const std = @import("std");
const fmt = std.fmt;
const testing = std.testing;

const DimensionComponent = struct { comptime_int, comptime_int };

// TODO add assert that components are sorted
/// Constructs a new dimension. Base dimensions should only have a single component of power 1.
/// For compound dimensions, the components should be passed sorted by their symbol ascending.
fn Dimension(comptime components_in: []const DimensionComponent) type {
    return struct {
        const This = @This();
        const components = components_in;

        pub inline fn isDimension() bool {
            return true;
        }

        fn CombineWith(Dim: type, is_multiply: bool) type {
            comptime var other_comps: [Dim.components.len]DimensionComponent = undefined;
            @memcpy(&other_comps, Dim.components);

            // get components from current
            comptime var new_comps = components;

            // add up overlapping components
            for (components, 0..) |comp, i| {
                const ch, const pow = comp;
                for (other_comps, 0..) |other_comp, j| {
                    const other_ch, const other_pow = other_comp;
                    if (ch == other_ch) {
                        const new_pow = if (is_multiply) pow + other_pow else pow - other_pow;
                        new_comps = new_comps[0..i] ++ .{.{ ch, new_pow }} ++ new_comps[i + 1 ..];
                        other_comps[j][1] = 0;
                    }
                }
            }

            // get non-overlapping components from rhs
            for (other_comps, 0..) |comp, i| {
                _, const pow = comp;
                if (pow != 0) {
                    const comp_to_add = if (is_multiply) blk: {
                        break :blk &[_]DimensionComponent{.{ other_comps[i][0], other_comps[i][1] }};
                    } else blk: {
                        break :blk &[_]DimensionComponent{.{ other_comps[i][0], other_comps[i][1] * -1 }};
                    };
                    new_comps = new_comps ++ comp_to_add;
                }
            }

            // TODO use better sort and pull this out to it's own function
            comptime var sorted_comps: []const DimensionComponent = &[_]DimensionComponent{};
            for (new_comps) |comp| {
                const ch, const pow = comp;
                if (pow != 0) {
                    comptime var idx = sorted_comps.len;
                    for (sorted_comps, 0..) |scomp, j| {
                        const sch, _ = scomp;
                        if (sch > ch) {
                            idx = j;
                            break;
                        }
                    }
                    sorted_comps = sorted_comps[0..idx] ++ &[_]DimensionComponent{comp} ++ sorted_comps[idx..];
                }
            }

            return Dimension(sorted_comps);
        }

        pub fn MultipliedBy(Dim: type) type {
            return CombineWith(Dim, true);
        }

        pub fn DividedBy(Dim: type) type {
            return CombineWith(Dim, false);
        }

        pub inline fn isBase() bool {
            return components.len == 1 and components[0][1] == 1;
        }

        pub fn str() []const u8 {
            comptime var str_out: []const u8 = "";
            comptime for (components) |comp| {
                str_out = str_out ++ fmt.comptimePrint("{u}:{d},", comp);
            };
            return str_out[0 .. str_out.len - 1]; // discard hanging comma
        }
    };
}

/// Used to create a dimension orthogonal to all other existing base dimensions.
/// This can be used to add custom dimensions (e.g. money), or encode semantics
/// into an existing dimension to treat them as orthogonal.
/// The symbol should be a unicode character.
fn BaseDimension(comptime symbol: u21) type {
    const dims: []const DimensionComponent = &[_]DimensionComponent{.{ symbol, 1 }};
    return Dimension(dims);
}

fn DimensionContainer(DimensionsIn: []type) type {
    return struct {
        const Dimensions = DimensionsIn;

        pub fn AddDimensions(DimensionsToAppend: type) type {
            return DimensionContainer(Dimensions ++ DimensionsToAppend);
        }

        pub fn AddDimension(DimensionIn: type) type {
            return DimensionContainer(Dimensions ++ DimensionIn);
        }
    };
}

pub const One = Dimension(&[0]DimensionComponent{});

// const DimensionsRegistry = DimensionContainer(.{
//     Time,
//     Length,
//     Mass,
//     Current,
//     Temperature,
//     Amount,
//     Luminosity,
//     Angle,
// });

test "Multiplying dimensions" {
    const should_be = Dimension(&[_]DimensionComponent{ .{ 'L', 1 }, .{ 'M', 1 } });
    const Length = BaseDimension('L');
    const Mass = BaseDimension('M');
    const lm = Length.MultipliedBy(Mass);
    try testing.expectEqual(
        lm,
        should_be,
    );

    const ml = Mass.MultipliedBy(Length);
    try testing.expectEqual(
        ml,
        should_be,
    );
}

test "Dividing dimensions" {
    const Length = BaseDimension('L');
    const Time = BaseDimension('T');
    const tl = Length.DividedBy(Time);
    try testing.expectEqual(
        tl,
        Dimension(&[_]DimensionComponent{ .{ 'L', 1 }, .{ 'T', -1 } }),
    );
}

test "Many operations" {
    const Length = BaseDimension('L');
    const Time = BaseDimension('T');
    const Current = BaseDimension('I');
    const Luminosity = BaseDimension('J');
    const lots = Length.MultipliedBy(Length).MultipliedBy(Time).DividedBy(Time).DividedBy(Current).DividedBy(Current).MultipliedBy(Luminosity);
    try testing.expectEqual(
        lots,
        Dimension(&[_]DimensionComponent{
            .{ 'I', -2 },
            .{ 'J', 1 },
            .{ 'L', 2 },
        }),
    );
}
