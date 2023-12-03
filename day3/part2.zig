const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;
const ArrayList = std.ArrayList;

const test_input =
    \\467..114..
    \\...*2.....
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

const Coord = struct {
    x: isize,
    y: isize,
};

const Grid = struct {
    data: [][]const u8,
    width: isize,
    height: isize,

    fn coordIsValid(self: *const Grid, coord: Coord) bool {
        return coord.x >= 0 and coord.y >= 0 and coord.x < self.width and coord.y < self.height;
    }
    fn get(self: *const Grid, coord: Coord) u8 {
        return self.data[@intCast(coord.y)][@intCast(coord.x)];
    }
    fn get_slice(self: *const Grid, start_coord: Coord, end_x: isize) []const u8 {
        return self.data[@intCast(start_coord.y)][@intCast(start_coord.x)..@intCast(end_x)];
    }
};

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
    var grid_data = ArrayList([]const u8).init(m);
    //const input = test_input;
    const input = real_input;

    var line_it = tokenizeAny(u8, input, "\n");
    while (line_it.next()) |line| {
        try grid_data.append(line);
    }
    const grid: Grid = .{
        .data = grid_data.items,
        .width = @intCast(grid_data.items[0].len),
        .height = @intCast(grid_data.items.len),
    };

    for (grid.data, 0..) |row, r| {
        gear: for (row, 0..) |ch, c| {
            if (ch != '*') {
                continue;
            }
            var num_nums: usize = 0;
            var nums: [2]usize = .{ 0, 0 };
            const top_left: Coord = .{ .x = @intCast(c - 1), .y = @intCast(r - 1) };
            const bot_right: Coord = .{ .x = @intCast(c + 2), .y = @intCast(r + 2) };
            var y = top_left.y;
            while (y < bot_right.y) : (y += 1) {
                var x = top_left.x;
                while (x < bot_right.x) : (x += 1) {
                    const coord: Coord = .{ .x = x, .y = y };
                    if (!grid.coordIsValid(coord)) {
                        continue;
                    }
                    if (!is_digit(grid.get(coord))) {
                        continue;
                    }
                    //print("{c}\n", .{grid.get(coord)});
                    if (num_nums >= 2) {
                        //print("continue\n", .{});
                        continue :gear;
                    }
                    var num_start: Coord = coord;
                    var num_end: Coord = coord;
                    while (grid.coordIsValid(num_start) and is_digit(grid.get(num_start))) : (num_start.x -= 1) {}
                    while (grid.coordIsValid(num_end) and is_digit(grid.get(num_end))) : (num_end.x += 1) {}
                    num_start.x += 1;
                    nums[num_nums] = try parseInt(usize, grid.get_slice(num_start, num_end.x), 10);
                    num_nums += 1;
                    if (num_end.x > top_left.x + 1) {
                        //print("break\n", .{});
                        break;
                    }
                }
            }
            //print("{}, {}\n", .{ nums[0], nums[1] });
            total += nums[0] * nums[1];
        }
    }
    //print("{s}\n", .{input});
    print("{}\n", .{total});
}
