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

fn arrayList(comptime T: type) std.ArrayList(T) {
    return std.ArrayList(T).init(m);
}

fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}

fn solve(galaxies: [][2]isize, row_counts: []usize, col_counts: []usize, expand_dist: usize) usize {
    var i: usize = 0;
    var j: usize = 0;
    var total: usize = 0;
    while (i < galaxies.len - 1) : (i += 1) {
        j = i + 1;
        while (j < galaxies.len) : (j += 1) {
            var dist: usize = 0;
            const minrow: usize = @intCast(@min(galaxies[i][0], galaxies[j][0]));
            const maxrow: usize = @intCast(@max(galaxies[i][0], galaxies[j][0]));
            for (minrow..maxrow) |rr| {
                if (row_counts[rr] == 0) {
                    dist += expand_dist;
                } else {
                    dist += 1;
                }
            }
            const mincol: usize = @intCast(@min(galaxies[i][1], galaxies[j][1]));
            const maxcol: usize = @intCast(@max(galaxies[i][1], galaxies[j][1]));
            for (mincol..maxcol) |cc| {
                if (col_counts[cc] == 0) {
                    dist += expand_dist;
                } else {
                    dist += 1;
                }
            }
            total += dist;
        }
    }
    return total;
}

pub fn main() !void {
    const input = try getInput();
    var line_it = strTokLine(input);
    var grid_arr = std.ArrayList([]const u8).init(m);
    var row_counts = std.ArrayList(usize).init(m);
    var col_counts = std.ArrayList(usize).init(m);
    var galaxies_arr = arrayList([2]isize);
    var r: isize = 0;
    while (line_it.next()) |line| {
        var c: isize = 0;
        try row_counts.append(0);
        try grid_arr.append(line);
        if (col_counts.items.len == 0) {
            try col_counts.appendNTimes(0, line.len);
        }
        for (line) |ch| {
            if (ch == '#') {
                try galaxies_arr.append(.{ r, c });
                row_counts.items[@intCast(r)] += 1;
                col_counts.items[@intCast(c)] += 1;
            }
            c += 1;
        }
        r += 1;
    }

    print("part 1: {}\n", .{solve(galaxies_arr.items, row_counts.items, col_counts.items, 2)});
    print("part 2: {}\n", .{solve(galaxies_arr.items, row_counts.items, col_counts.items, 1000000)});
}
