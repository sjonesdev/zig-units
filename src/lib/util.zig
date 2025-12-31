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

pub fn countNewlines(str: []const u8) usize {
    @setEvalBranchQuota(str.len * 8);
    var cnt = 0;
    for (str) |ch| {
        if (ch == '\n') cnt += 1;
    }
    return cnt;
}

pub inline fn filterNewlines(comptime str: []const u8) *const [str.len - countNewlines(str)]u8 {
    comptime {
        var buf: [str.len - countNewlines(str)]u8 = undefined;
        var i = 0;
        for (str) |ch| {
            if (ch == '\n') continue;
            buf[i] = ch;
            i += 1;
        }
        const final = buf;
        return &final;
    }
}
