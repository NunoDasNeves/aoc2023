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

pub fn main() !void {
    const input = try getInput();
    var line_it = strTokLine(input);
    var nums_list = std.ArrayList(std.ArrayList(i64)).init(m);
    var total: i64 = 0;
    while (line_it.next()) |line| {
        var it = strTokSpace(line);
        var curr_list = std.ArrayList(i64).init(m);
        while (it.next()) |s| {
            try curr_list.append(try parseInt(i64, s, 10));
        }
        try nums_list.append(curr_list);
        while (true) {
            const prev_list = curr_list;
            curr_list = std.ArrayList(i64).init(m);
            var t: i64 = 0;
            for (0..prev_list.items.len - 1) |i| {
                const diff = prev_list.items[i + 1] - prev_list.items[i];
                t += diff;
                try curr_list.append(diff);
            }
            try nums_list.append(curr_list);
            if (t == 0) {
                break;
            }
        }
        try nums_list.items[nums_list.items.len - 1].append(0);

        var i: usize = nums_list.items.len - 2;
        while (true) : (i -= 1) {
            var arr = &nums_list.items[i];
            var prev_arr = &nums_list.items[i + 1];
            try arr.append(prev_arr.getLast() + arr.getLast());
            if (i == 0) {
                break;
            }
        }
        for (nums_list.items) |*list| {
            print("{any}\n", .{list.items});
        }
        total += nums_list.items[0].getLast();
        for (nums_list.items) |*list| {
            list.deinit();
        }
        nums_list.clearAndFree();
    }
    print("{}\n", .{total});
}
