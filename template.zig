const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var line_it = util.strTokLine(input);

    while (line_it.next()) |line| {
        total += 1;
        _ = line;
    }

    if (part2) {}

    return total;
}

pub fn main() !void {
    const input = try util.getInput();
    print("{s}\n", .{try solve(input, false)});
    //print("{s}\n", .{try solve(input, true)});
}
