const std = @import("std");

pub inline fn isNumberType(T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

pub inline fn isNumber(val: anytype) bool {
    return isNumberType(@TypeOf(val));
}

pub fn countNewlines(comptime str: []const u8) usize {
    comptime {
        var cnt = 0;
        for (str) |ch| {
            if (ch == '\n') cnt += 1;
        }
        return cnt;
    }
}

pub inline fn filterNewlines(comptime str: []const u8) []const u8 { //[(str.len - countNewlines(str))]u8 {
    comptime {
        var arr: [str.len - countNewlines(str)]u8 = undefined;
        var i = 0;
        for (str) |ch| {
            if (ch == '\n') continue;
            arr[i] = ch;
            i += 1;
        }
        const arr_final = arr;
        return &arr_final;
    }
}

pub fn typeNameOrFunction(T: type) []const u8 {
    const name = @typeName(T);
    var iter = std.mem.tokenizeAny(u8, name, "(");
    return iter.peek() orelse iter.rest();
}

test typeNameOrFunction {
    try std.testing.expectEqualSlices(u8, "f64", typeNameOrFunction(f64));
    try std.testing.expectEqualSlices(u8, "bounded_array.BoundedArrayAligned", typeNameOrFunction(std.BoundedArray(u8, 128)));
}
