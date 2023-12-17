const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const HM = std.AutoHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var line_it = u.strTokLine(input);

    while (line_it.next()) |line| {
        total += 1;
        _ = line;
    }

    if (part2) {}

    return total;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    //print("{}\n", .{try solve(input, true)});
}
