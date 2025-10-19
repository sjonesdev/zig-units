pub inline fn isNumberType(T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .comptime_int, .comptime_float => true,
        else => false,
    };
}

pub inline fn isNumber(val: anytype) bool {
    return isNumberType(@TypeOf(val));
}
