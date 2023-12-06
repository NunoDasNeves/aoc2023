const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const trim = std.mem.trim;
const ascii = std.ascii;

fn strTokAny(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeAny = std.mem.tokenizeAny;
    return tokenizeAny(u8, str, delimiters);
}

fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeSequence = std.mem.tokenizeSequence;
    return tokenizeSequence(u8, str, delimiters);
}

fn strTokLine(str: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, '\n');
}

fn strTokSpace(str: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, ' ');
}

fn strTrim(str: []const u8, values: []const u8) []const u8 {
    return trim(u8, str, values);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    const f = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    defer f.close();
    return try f.readToEndAlloc(m, std.math.maxInt(usize));
}

pub fn main() !void {
    const input = try getInput();

    print("{s}\n", .{input});
}
