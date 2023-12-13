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

fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .sequence) {
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

fn find_pattern(nums: []u64, mul: usize) ?usize {
    var start: usize = 0;
    while (start < nums.len - 1) : (start += 1) {
        var i: usize = start;
        var j: usize = start + 1;
        var flag: bool = false;
        while (true) {
            if (nums[i] != nums[j]) {
                break;
            }
            if (i == 0 or j >= nums.len - 1) {
                flag = true;
                break;
            }
            i -= 1;
            j += 1;
        }
        //print("{} {}\n", .{ i, j });
        if (flag) {
            //print("start {}\n", .{start});
            return (start + 1) * mul;
        }
    }
    return null;
}

pub fn main() !void {
    const input = try getInput();
    var pat_it = strTokSeq(input, "\n\n");
    var total: usize = 0;
    while (pat_it.next()) |_pat| {
        const pat_str = strTrim(_pat, "\n ");
        var pat_arr = std.ArrayList([]const u8).init(m);
        defer pat_arr.deinit();
        var line_it = strTokLine(pat_str);
        while (line_it.next()) |line| {
            try pat_arr.append(line);
        }
        const pat = pat_arr.items;
        //for (pat) |line| {
        //    print("{s}\n", .{line});
        //}
        //print("\n", .{});
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

        //print("{any}\n", .{rows});
        //print("{any}\n", .{cols});

        if (find_pattern(rows, 100)) |num| {
            total += num;
        } else if (find_pattern(cols, 1)) |num| {
            total += num;
        }
    }
    print("{}\n", .{total});
}
