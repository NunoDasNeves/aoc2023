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

const Seed = struct { seed: usize, len: usize, src_num: usize, curr: usize };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const input = test_input;
    const input = real_input;
    const total: usize = 0;
    _ = total;
    const m = gpa.allocator();
    var line_it = tokenizeAny(u8, input, "\n");
    var seeds_it = tokenizeAny(u8, line_it.next().?, " ");
    var seeds_arr = ArrayList(Seed).init(m);
    while (seeds_it.next()) |seed_str| {
        const num = parseInt(usize, seed_str, 10) catch continue;
        const len = try parseInt(usize, seeds_it.next().?, 10);
        try seeds_arr.append(.{ .seed = num, .len = len, .src_num = 0, .curr = num });
    }
    print("{any}\n", .{seeds_arr.items});
    var src_num: usize = 0;
    while (line_it.next()) |line| {
        if (is_digit(line[0])) {
            var it = tokenizeAny(u8, line, " ");
            const dest = try parseInt(usize, it.next().?, 10);
            const src = try parseInt(usize, it.next().?, 10);
            const len = try parseInt(usize, it.next().?, 10);
            print("{} {} {}\n", .{ dest, src, len });
            const seeds = try seeds_arr.toOwnedSlice();
            for (seeds) |cseed| {
                //print("{}\n", .{i});
                var seed = cseed;
                if (seed.src_num != src_num) {
                    try seeds_arr.append(seed);
                    continue;
                }
                const seed_end = seed.curr + seed.len;
                // past end
                if (seed.curr >= src + len) {
                    try seeds_arr.append(seed);
                    continue;
                }
                // 1: starts below
                if (seed.curr < src) {
                    // before start
                    if (seed_end < src) {
                        try seeds_arr.append(seed);
                        continue;
                    }

                    const below_len = src - seed.curr;
                    const below: Seed = .{
                        .seed = seed.seed,
                        .curr = seed.curr,
                        .len = below_len,
                        .src_num = seed.src_num,
                    };
                    try seeds_arr.append(below);
                    seed.curr += below_len;
                    seed.len -= below_len;
                }
                // 2: ends after
                if (seed_end > src + len) {
                    print("after\n", .{});
                    const above_len = seed_end - (src + len);
                    const above: Seed = .{
                        .seed = seed.seed,
                        .curr = src + len,
                        .len = above_len,
                        .src_num = seed.src_num,
                    };
                    try seeds_arr.append(above);
                    seed.len -= above_len;
                }
                seed.src_num += 1;
                seed.curr = dest + (seed.curr - src);
                try seeds_arr.append(seed);
            }
            print("{any}\n", .{seeds_arr.items});
        } else {
            var it = tokenizeAny(u8, line, "- ");
            const src_name = it.next().?;
            _ = it.next().?;
            const dest_name = it.next().?;
            print("{s} {s}\n", .{ src_name, dest_name });
            src_num += 1;
            for (seeds_arr.items) |*seed| {
                seed.src_num = src_num;
            }
        }
    }
    var min = seeds_arr.items[0].curr;
    for (seeds_arr.items) |*seed| {
        min = @min(min, seed.curr);
    }
    print("{}\n", .{min});
    //print("{s}\n", .{input});

}
