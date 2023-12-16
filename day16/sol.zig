const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

const Dir = enum(u8) {
    N = '^',
    W = '<',
    S = 'V',
    E = '>',
    fn opp(self: @This()) Dir {
        switch (self) {
            .N => .S,
            .W => .E,
            .S => .N,
            .E => .W,
        }
    }
    fn change(self: @This(), ch: u8, ret: *[2]Dir) []Dir {
        switch (ch) {
            '.' => {
                ret[0] = self;
                return ret[0..1];
            },
            '/' => {
                ret[0] = switch (self) {
                    .N => .E,
                    .W => .S,
                    .S => .W,
                    .E => .N,
                };
                return ret[0..1];
            },
            '\\' => {
                ret[0] = switch (self) {
                    .N => .W,
                    .W => .N,
                    .S => .E,
                    .E => .S,
                };
                return ret[0..1];
            },
            '|' => {
                switch (self) {
                    .N => {
                        ret[0] = .N;
                        return ret[0..1];
                    },
                    .W => {
                        ret[0] = .N;
                        ret[1] = .S;
                    },
                    .S => {
                        ret[0] = .S;
                        return ret[0..1];
                    },
                    .E => {
                        ret[0] = .N;
                        ret[1] = .S;
                    },
                }
                return ret[0..2];
            },
            '-' => {
                switch (self) {
                    .W => {
                        ret[0] = .W;
                        return ret[0..1];
                    },
                    .N => {
                        ret[0] = .E;
                        ret[1] = .W;
                    },
                    .E => {
                        ret[0] = .E;
                        return ret[0..1];
                    },
                    .S => {
                        ret[0] = .E;
                        ret[1] = .W;
                    },
                }
                return ret[0..2];
            },
            else => unreachable,
        }
    }
};

const Tile = struct {
    ch: u8,
    energized: bool,
    dir_buf: [4]Dir,
    enter_dirs: []Dir,
    fn appendDir(self: *@This(), dir: Dir) void {
        if (self.enter_dirs.len == 4) {
            unreachable;
        }
        self.dir_buf[self.enter_dirs.len] = dir;
        self.enter_dirs = self.dir_buf[0 .. self.enter_dirs.len + 1];
    }
};

const Light = struct {
    pos: [2]usize,
    dir: Dir,
    fn move(self: @This(), grid: [][]Tile, ret: *[2]Light) []Light {
        var num: usize = 0;
        var dir_buf: [2]Dir = undefined;
        const next_dirs = self.dir.change(grid[self.pos[0]][self.pos[1]].ch, &dir_buf);
        //print("{any}\n", .{next_dirs});
        for (next_dirs) |d| {
            ret[num] = self;
            ret[num].dir = d;
            switch (d) {
                .N => {
                    if (self.pos[0] == 0) continue;
                    ret[num].pos[0] -= 1;
                },
                .W => {
                    if (self.pos[1] == 0) continue;
                    ret[num].pos[1] -= 1;
                },
                .S => {
                    if (self.pos[0] == grid.len - 1) continue;
                    ret[num].pos[0] += 1;
                },
                .E => {
                    if (self.pos[1] == grid[0].len - 1) continue;
                    ret[num].pos[1] += 1;
                },
            }
            num += 1;
        }
        return ret[0..num];
    }
};

fn reset_grid(grid: [][]Tile) void {
    for (grid) |row| {
        for (row) |*tile| {
            tile.energized = false;
            tile.enter_dirs = &.{};
        }
    }
}

fn solve(input: []const u8, part2: bool) !usize {
    var grid_arr = std.ArrayList([]Tile).init(m);
    var line_it = util.strTokLine(input);
    while (line_it.next()) |line| {
        const row = try m.alloc(Tile, line.len);
        for (row, 0..) |*tile, c| {
            tile.ch = line[c];
        }
        try grid_arr.append(row);
    }
    var grid = try grid_arr.toOwnedSlice();
    var best: usize = 0;
    var start_lights = std.ArrayList(Light).init(m);
    if (part2) {
        for (0..grid.len) |r| {
            try start_lights.append(.{ .pos = .{ r, 0 }, .dir = .E });
            try start_lights.append(.{ .pos = .{ r, grid[0].len - 1 }, .dir = .W });
        }
        for (0..grid[0].len) |c| {
            try start_lights.append(.{ .pos = .{ 0, c }, .dir = .S });
            try start_lights.append(.{ .pos = .{ grid.len - 1, c }, .dir = .N });
        }
    } else {
        try start_lights.append(.{ .pos = .{ 0, 0 }, .dir = .E });
    }

    for (start_lights.items) |start_light| {
        reset_grid(grid);
        var total: usize = 0;
        var light_arr = std.ArrayList(Light).init(m);
        defer light_arr.deinit();
        try light_arr.append(start_light);
        loop: while (light_arr.items.len > 0) {
            const light = light_arr.pop();
            //print("{any}\n", .{light});
            const tile = &grid[light.pos[0]][light.pos[1]];
            for (tile.enter_dirs) |dir| {
                if (dir == light.dir) {
                    continue :loop;
                }
            }
            tile.energized = true;
            tile.appendDir(light.dir);
            var light_buf: [2]Light = undefined;
            const new_lights = light.move(grid, &light_buf);
            try light_arr.appendSlice(new_lights);
        }
        for (grid, 0..) |row, r| {
            _ = r;
            for (row, 0..) |tile, c| {
                _ = c;
                if (tile.energized) {
                    total += 1;
                }
                if (tile.enter_dirs.len > 0) {
                    //print("{c}", .{@intFromEnum(tile.enter_dirs[0])});
                } else {
                    //print("{c}", .{tile.ch});
                }
            }
            //print("\n", .{});
        }
        best = @max(best, total);
    }
    //print("\n", .{});
    return best;
}

pub fn main() !void {
    const input = try util.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
