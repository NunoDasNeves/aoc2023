const std = @import("std");

const parseInt = std.fmt.parseInt;

const trim = std.mem.trim;
const tokenizeScalar = std.mem.tokenizeScalar;
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSequence = std.mem.tokenizeSequence;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

pub fn strTokAny(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    return tokenizeAny(u8, str, delimiters);
}

pub fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .sequence) {
    return tokenizeSequence(u8, str, delimiters);
}

pub fn strTokLine(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    return tokenizeScalar(u8, str, '\n');
}

pub fn strTokSpace(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    return tokenizeScalar(u8, str, ' ');
}

pub fn strTrim(str: []const u8, values: []const u8) []const u8 {
    return trim(u8, str, values);
}

pub fn parseIntListAny(comptime T: type, str: []const u8, delimiters: []const u8) ![]T {
    var arr = std.ArrayList(T).init(m);
    var it = tokenizeAny(u8, str, delimiters);
    while (it.next()) |s| {
        try arr.append(try parseInt(T, s, 10));
    }
    return arr.toOwnedSlice();
}

pub fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}
