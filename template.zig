const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

pub fn main() !void {
    const input = try util.getInput();
    var line_it = util.strTokLine(input);
    while (line_it.next()) |line| {
        _ = line;
    }
    print("{s}\n", .{input});
}
