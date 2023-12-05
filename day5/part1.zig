const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;
const ArrayList = std.ArrayList;

const test_input =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;
const real_input = @embedFile("input");

fn is_digit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const input = test_input;
    const input = real_input;
    const total: usize = 0;
    _ = total;
    const m = gpa.allocator();
    var line_it = tokenizeAny(u8, input, "\n");
    var seeds_it = tokenizeAny(u8, line_it.next().?, " ");
    var seeds_arr = ArrayList(struct { seed: usize, src: usize, curr: usize }).init(m);
    while (seeds_it.next()) |seed_str| {
        const num = parseInt(usize, seed_str, 10) catch continue;
        try seeds_arr.append(.{ .seed = num, .src = 0, .curr = num });
    }
    const seeds = seeds_arr.items;
    var src_num: usize = 0;
    while (line_it.next()) |line| {
        if (is_digit(line[0])) {
            var it = tokenizeAny(u8, line, " ");
            const dest = try parseInt(usize, it.next().?, 10);
            const src = try parseInt(usize, it.next().?, 10);
            const len = try parseInt(usize, it.next().?, 10);
            print("{} {} {}\n", .{ dest, src, len });
            for (seeds) |*seed| {
                if (seed.src == src_num and seed.curr >= src and seed.curr < src + len) {
                    seed.curr = dest + (seed.curr - src);
                    seed.src += 1;
                }
            }
        } else {
            var it = tokenizeAny(u8, line, "- ");
            const src_name = it.next().?;
            _ = it.next().?;
            const dest_name = it.next().?;
            print("{s} {s}\n", .{ src_name, dest_name });
            src_num += 1;
            for (seeds) |*seed| {
                seed.src = src_num;
            }
        }
    }
    var min = seeds[0].curr;
    for (seeds) |*seed| {
        min = @min(min, seed.curr);
    }
    print("{}\n", .{min});
    //print("{s}\n", .{input});

}
