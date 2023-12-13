const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn findPattern(nums: []u64, errors: usize) ?usize {
    var start: usize = 0;
    //print("nums {any}\n", .{nums});
    while (start < nums.len - 1) : (start += 1) {
        var i: usize = start;
        var j: usize = start + 1;
        var flag: bool = false;
        var err_count: usize = 0;
        while (true) {
            var bits: u64 = nums[i] ^ nums[j];
            while (bits != 0) : (err_count += 1) {
                bits &= bits - 1;
            }
            //print("[{} {}] bits: {b} errs: {}\n", .{ nums[i], nums[j], nums[i] & ~nums[j], err_count });
            if (err_count > errors) {
                break;
            }
            if (i == 0 or j >= nums.len - 1) {
                flag = true;
                break;
            }
            i -= 1;
            j += 1;
        }
        //print("errors {}\n", .{err_count});

        if (flag and err_count == errors) {
            return start + 1;
        }
    }
    return null;
}

fn solve(input: []const u8, part2: bool) !usize {
    var pat_it = util.strTokSeq(input, "\n\n");
    var total: usize = 0;

    while (pat_it.next()) |_pat| {
        const pat_str = util.strTrim(_pat, "\n ");
        var pat_arr = std.ArrayList([]const u8).init(m);
        defer pat_arr.deinit();
        var line_it = util.strTokLine(pat_str);
        while (line_it.next()) |line| {
            try pat_arr.append(line);
        }
        const pat = pat_arr.items;
        if (pat.len > 64 or pat[0].len > 64) {
            unreachable;
        }
        var row_arr = std.ArrayList(u64).init(m);
        for (pat) |line| {
            var bits: u64 = 0;
            for (line, 0..) |ch, i| {
                if (ch == '#') {
                    bits |= @as(u64, 1) << @intCast(i);
                }
            }
            try row_arr.append(bits);
        }
        const rows = row_arr.items;

        var col_arr = std.ArrayList(u64).init(m);
        for (0..pat[0].len) |c| {
            var bits: u64 = 0;
            for (0..pat.len) |r| {
                const ch = pat[r][c];
                if (ch == '#') {
                    bits |= @as(u64, 1) << @intCast(r);
                }
            }
            try col_arr.append(bits);
        }
        const cols = col_arr.items;

        const col_1 = findPattern(cols, if (part2) 1 else 0);
        const row_1 = findPattern(rows, if (part2) 1 else 0);
        if (col_1) |c| {
            total += c;
        } else if (row_1) |r| {
            total += r * 100;
        } else {
            unreachable;
        }
    }
    return total;
}

pub fn main() !void {
    const input = try util.getInput();

    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
