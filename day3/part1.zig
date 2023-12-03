const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;
const ArrayList = std.ArrayList;

const test_input =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#100
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
;
const real_input = @embedFile("input");

fn is_digit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

fn find_symbol(grid: ArrayList([]const u8), num_r: usize, num_start_c: usize, num_end_c: usize) bool {
    const start_r = if (num_r == 0) num_r else num_r - 1;
    var end_r = num_r + 2;
    while (end_r >= grid.items.len) {
        end_r -= 1;
    }
    const start_c = if (num_start_c == 0) num_start_c else num_start_c - 1;
    const end_c = if (num_end_c == grid.items[0].len) num_end_c else num_end_c + 1;
    //print("r {}:{} c {}:{}\n", .{ start_r, end_r, start_c, end_c });
    for (start_r..end_r) |r| {
        for (start_c..end_c) |c| {
            const ch: u8 = grid.items[r][c];
            if (ch != '.' and !is_digit(ch)) {
                return true;
            }
        }
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const m = gpa.allocator();
    var total: usize = 0;
    total += 0;
    var grid = ArrayList([]const u8).init(m);
    //const input = test_input;
    const input = real_input;

    var line_it = tokenizeAny(u8, input, "\n");
    while (line_it.next()) |line| {
        try grid.append(line);
    }
    for (grid.items, 0..) |row, r| {
        var start_c: usize = 0;
        var num: ?[]const u8 = null;
        //print("{s}\n", .{row});
        for (row, 0..) |ch, c| {
            if (is_digit(ch)) {
                if (num == null) {
                    start_c = c;
                    num = row[c..c];
                }
                num.?.len += 1;
            }
            if (!is_digit(ch) or c == row.len - 1) {
                if (num != null) {
                    //print("{s}\n", .{num.?});
                    if (find_symbol(grid, r, start_c, start_c + num.?.len)) {
                        const num_int = try parseInt(usize, num.?, 10);
                        total += num_int;
                    }
                }
                num = null;
            }
        }
    }
    //print("{s}\n", .{input});
    print("{}\n", .{total});
}
