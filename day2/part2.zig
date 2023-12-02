const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;

const test_input =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
;
const real_input = @embedFile("input");

pub fn main() !void {
    var total: usize = 0;
    //const input = test_input;
    const input = real_input;
    var gameIt = tokenizeAny(u8, input, "\n");

    while (gameIt.next()) |game| {
        var gameNumIt = splitSequence(u8, game, ": ");
        _ = gameNumIt.next();
        const sets_str = gameNumIt.next().?;
        var maxSet: [3]usize = .{ 0, 0, 0 };
        var cube_it = tokenizeAny(u8, sets_str, ";,");
        while (cube_it.next()) |cube_untrimmed| {
            const cube = trim(u8, cube_untrimmed, " ");
            var it = splitSequence(
                u8,
                cube,
                " ",
            );
            const numStr = it.next().?;
            const numCubes = try parseInt(usize, numStr, 10);
            const color = it.next().?;
            const ch = color[0];
            const index: u8 = switch (ch) {
                'r' => 0,
                'g' => 1,
                'b' => 2,
                else => unreachable,
            };
            if (numCubes > maxSet[index]) {
                maxSet[index] = numCubes;
            }
        }
        total += maxSet[0] * maxSet[1] * maxSet[2];
    }

    //print("{s}\n", .{input});
    print("{}\n", .{total});
}
