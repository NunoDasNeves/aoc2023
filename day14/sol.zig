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

fn get_load(grid: [][]u8) usize {
    var load: usize = 0;
    for (grid, 0..) |row, r| {
        for (row) |ch| {
            if (ch == 'O') {
                load += grid.len - r;
            }
        }
    }
    return load;
}

const Ctx = struct {
    pub fn hash(self: @This(), grid: [][]u8) u64 {
        _ = self;
        var ret: u64 = 0;
        for (grid) |row| {
            ret ^= std.hash.CityHash64.hash(row);
        }
        return ret;
    }
    pub fn eql(self: @This(), a: [][]u8, b: [][]u8) bool {
        _ = self;
        for (a, 0..) |row_a, r| {
            for (row_a, 0..) |ch_a, c| {
                if (ch_a != b[r][c]) {
                    return false;
                }
            }
        }
        return true;
    }
};

fn solve(input: []const u8, part2: bool) !usize {
    var map = std.HashMap([][]u8, usize, Ctx, 80).init(m);
    var line_it = util.strTokLine(input);
    var grid_arr = std.ArrayList([]u8).init(m);
    while (line_it.next()) |line| {
        const row = try m.alloc(u8, line.len);
        @memcpy(row, line);
        try grid_arr.append(row);
    }
    const grid = try grid_arr.toOwnedSlice();
    for (grid) |row| {
        print("{s}\n", .{row});
    }
    print("\n", .{});
    if (part2) {
        var loads = std.ArrayList(usize).init(m);
        var loop_start: usize = 0;
        var loop_len: usize = 0;
        for (0..1000) |i| {
            for (0..4) |j| {
                tilt(grid, j);
            }
            try loads.append(get_load(grid));
            if (map.get(grid)) |idx| {
                loop_start = idx;
                loop_len = i - idx;
                break;
            }
            const copy = try m.alloc([]u8, grid.len);
            for (copy, 0..) |*row, r| {
                row.* = try m.alloc(u8, grid[0].len);
                @memcpy(row.*, grid[r]);
            }
            try (map.put(copy, i));
            print("{}: {}\n", .{ i, get_load(grid) });
        }
        print("loop start: {}\nloop len:{}\n", .{ loop_start, loop_len });
        const offset: usize = (1000000000 - (loop_start + 1)) % loop_len;
        const load = loads.items[loop_start + offset];
        print("offset: {}\n", .{offset});
        return load;
    }

    tilt(grid, 0);
    //for (grid) |row| {
    //    print("{s}\n", .{row});
    //}
    return get_load(grid);
}

pub fn main() !void {
    const input = try util.getInput();
    //print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
