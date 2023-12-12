const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const trim = std.mem.trim;
const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn strTokAny(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeAny = std.mem.tokenizeAny;
    return tokenizeAny(u8, str, delimiters);
}

fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeSequence = std.mem.tokenizeSequence;
    return tokenizeSequence(u8, str, delimiters);
}

fn strTokLine(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, '\n');
}

fn strTokSpace(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, ' ');
}

fn strTrim(str: []const u8, values: []const u8) []const u8 {
    return trim(u8, str, values);
}

fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}

fn permute(memo: *std.hash_map.AutoHashMap([3]usize, usize), springs: []const u8, possible: []u8, groups: []usize, num_broken: usize, idx: usize) !usize {
    if (idx == springs.len) {
        if (groups.len > 0) {
            return 0;
        }
        //print("  {s}\n", .{possible});
        return 1;
    }
    const key = [3]usize{ groups.len, num_broken, idx };
    if (memo.get(key)) |val| {
        return val;
    }

    var count: usize = 0;

    const chs = if (springs[idx] == '?') ([2]u8{ '.', '#' })[0..2] else ([2]u8{ springs[idx], 'X' })[0..1];
    for (chs) |ch| {
        var new_groups = groups;
        var new_num_broken = num_broken;
        if (ch == '.') {
            if (num_broken > 0) {
                if (num_broken != groups[0]) {
                    continue;
                }
                new_groups = groups[1..];
                new_num_broken = 0;
            }
        } else if (ch == '#') {
            new_num_broken = num_broken + 1;
            if (groups.len == 0) {
                continue;
            }
            if (new_num_broken > groups[0]) {
                continue;
            }
        }
        //print("  {s}\n", .{springs});
        possible[idx] = ch;
        count += try permute(memo, springs, possible, new_groups, new_num_broken, idx + 1);
    }
    try memo.put(key, count);

    return count;
}

fn solve(input: []const u8, part2: bool) !usize {
    var line_it = strTokLine(input);
    var count: usize = 0;
    while (line_it.next()) |line| {
        var a_it = strTokAny(line, " ,");
        const springs_str = a_it.next().?;
        var springs_arr = std.ArrayList(u8).init(m);
        try springs_arr.append('.');
        if (part2) {
            for (0..5) |i| {
                if (i > 0) {
                    try springs_arr.append('?');
                }
                try springs_arr.appendSlice(springs_str);
            }
        } else {
            try springs_arr.appendSlice(springs_str);
        }
        try springs_arr.append('.');
        var possible_arr = std.ArrayList(u8).init(m);
        try possible_arr.appendSlice(springs_arr.items);

        var nums_arr = std.ArrayList(usize).init(m);
        defer nums_arr.deinit();
        while (a_it.next()) |num_str| {
            try nums_arr.append(try parseUnsigned(usize, num_str, 10));
        }
        var groups_arr = std.ArrayList(usize).init(m);
        if (part2) {
            for (0..5) |_| {
                try groups_arr.appendSlice(nums_arr.items);
            }
        } else {
            try groups_arr.appendSlice(nums_arr.items);
        }

        var memo = std.hash_map.AutoHashMap([3]usize, usize).init(m);
        defer memo.deinit();
        const groups = groups_arr.items;
        const springs = springs_arr.items;
        const possible = possible_arr.items;
        //print("{s}, {any}\n", .{ springs, groups });
        count += try permute(&memo, springs, possible, groups, 0, 0);
    }
    return count;
}

pub fn main() !void {
    const input = try getInput();

    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
