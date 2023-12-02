const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;

const test_input =
    \\
    \\
;
const real_input = @embedFile("input");

pub fn main() !void {
    var total: usize = 0;
    total += 0;
    const input = test_input;
    //const input = real_input;

    print("{s}\n", .{input});
    print("{}\n", .{total});
}
