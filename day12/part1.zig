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

fn matches(possible: []u8, groups: []usize) bool {
    var num_broken: usize = 0;
    var in_group: bool = false;
    var curr_group: ?usize = null;
    for (possible) |ch| {
        if (ch == '.') {
            if (in_group) {
                in_group = false;
                if (num_broken != groups[curr_group.?]) {
                    return false;
                } else {
                    num_broken = 0;
                }
            }
        } else if (ch == '#') {
            if (num_broken == 0) {
                if (curr_group == null) {
                    curr_group = 0;
                } else {
                    curr_group.? += 1;
                }
            }
            if (curr_group.? >= groups.len) {
                return false;
            }
            in_group = true;
            num_broken += 1;
            if (num_broken > groups[curr_group.?]) {
                return false;
            }
        }
    }
    if (curr_group == null) {
        if (groups.len != 0) {
            return false;
        }
        return true;
    }
    if (in_group and num_broken != groups[curr_group.?]) {
        return false;
    }
    //print("{?}\n", .{curr_group});
    return curr_group.? == groups.len - 1;
}

fn permute(springs: []const u8, groups: []usize, possible: []u8, idx: usize) usize {
    if (idx == possible.len) {
        if (matches(possible, groups)) {
            print("  {s}\n", .{possible});
            return 1;
        }

        return 0;
    }

    var next_idx: usize = idx + 1;
    while (next_idx < possible.len) : (next_idx += 1) {
        if (springs[next_idx] == '?') {
            break;
        }
    }

    var count: usize = 0;
    for ([_]u8{ '.', '#' }) |ch| {
        possible[idx] = ch;
        count += permute(springs, groups, possible, next_idx);
    }

    return count;
}

pub fn main() !void {
    const input = try getInput();
    var line_it = strTokLine(input);
    var count: usize = 0;
    while (line_it.next()) |line| {
        var a_it = strTokAny(line, " ,");
        const springs = a_it.next().?;
        var nums_arr = std.ArrayList(usize).init(m);
        defer nums_arr.deinit();
        var possible_arr = std.ArrayList(u8).init(m);
        defer possible_arr.deinit();
        while (a_it.next()) |num_str| {
            try nums_arr.append(try parseUnsigned(usize, num_str, 10));
        }
        for (springs) |s| {
            if (s == '?') {
                try possible_arr.append('.');
            } else {
                try possible_arr.append(s);
            }
        }
        const groups = nums_arr.items;
        const possible = possible_arr.items;
        var next_idx: usize = 0;
        while (next_idx < possible.len) : (next_idx += 1) {
            if (springs[next_idx] == '?') {
                break;
            }
        }
        //print("{s}, {any}\n", .{ springs, groups });
        count += permute(springs, groups, possible, next_idx);
    }
    print("{}\n", .{count});
}
