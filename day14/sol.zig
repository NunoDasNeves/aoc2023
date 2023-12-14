const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn get_N(grid: [][]u8, i: usize, x: usize) *u8 {
    return &grid[grid.len - i - 1][x];
}

fn get_W(grid: [][]u8, i: usize, x: usize) *u8 {
    return &grid[x][grid[0].len - i - 1];
}

fn get_S(grid: [][]u8, i: usize, x: usize) *u8 {
    return &grid[i][x];
}

fn get_E(grid: [][]u8, i: usize, x: usize) *u8 {
    return &grid[x][i];
}

const GetFn = *const fn ([][]u8, usize, usize) *u8;

fn _tilt(grid: [][]u8, i_num: usize, x_num: usize, get_fn: GetFn) void {
    while (true) {
        var count: usize = 0;
        for (0..x_num) |x| {
            for (0..i_num) |i| {
                if (i == i_num - 1) {
                    continue;
                }
                const curr = get_fn(grid, i, x);
                const next = get_fn(grid, i + 1, x);
                if (curr.* == 'O' and next.* == '.') {
                    curr.* = '.';
                    next.* = 'O';
                    count += 1;
                }
            }
        }
        if (count == 0) {
            break;
        }
    }
}

fn tilt(grid: [][]u8, dir: usize) void {
    switch (dir) {
        0 => _tilt(grid, grid.len, grid[0].len, get_N),
        1 => _tilt(grid, grid[0].len, grid.len, get_W),
        2 => _tilt(grid, grid.len, grid[0].len, get_S),
        3 => _tilt(grid, grid[0].len, grid.len, get_E),
        else => unreachable,
    }
}

fn solve(input: []const u8, part2: bool) !usize {
    var line_it = util.strTokLine(input);
    var grid_arr = std.ArrayList([]u8).init(m);
    while (line_it.next()) |line| {
        const row = try m.alloc(u8, line.len);
        @memcpy(row, line);
        try grid_arr.append(row);
    }
    const grid = grid_arr.items;
    for (grid) |row| {
        print("{s}\n", .{row});
    }
    print("\n", .{});
    if (part2) {
        for (0..1000000000) |_| {
            for (0..4) |i| {
                tilt(grid, i);
            }
        }
    } else {
        tilt(grid, 0);
    }
    var load: usize = 0;
    for (grid, 0..) |row, r| {
        for (row) |ch| {
            if (ch == 'O') {
                load += grid.len - r;
            }
        }
    }
    for (grid) |row| {
        print("{s}\n", .{row});
    }
    return load;
}

pub fn main() !void {
    const input = try util.getInput();
    print("{}\n", .{try solve(input, false)});
    //print("{}\n", .{try solve(input, true)});
}
