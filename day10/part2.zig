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

fn getInput() ![]u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}

const Dir = enum {
    N,
    S,
    E,
    W,
    fn from_offset(off: [2]isize) @This() {
        if (off[0] > 0) {
            if (off[1] != 0) {
                unreachable;
            }
            return .S;
        } else if (off[0] < 0) {
            if (off[1] != 0) {
                unreachable;
            }
            return .N;
        } else if (off[1] > 0) {
            return .E;
        }
        return .W;
    }
    fn to_offset(self: @This()) [2]isize {
        return switch (self) {
            .N => .{ -1, 0 },
            .S => .{ 1, 0 },
            .E => .{ 0, 1 },
            .W => .{ 0, -1 },
        };
    }
};

fn dirs_to_ch(dir0: Dir, dir1: Dir) u8 {
    return switch (dir0) {
        .N => switch (dir1) {
            .N => '|',
            .S => '|',
            .E => 'F',
            .W => '7',
        },
        .S => switch (dir1) {
            .N => '|',
            .S => '|',
            .E => 'L',
            .W => 'J',
        },
        .E => switch (dir1) {
            .N => 'J',
            .S => '7',
            .E => '-',
            .W => '-',
        },
        .W => switch (dir1) {
            .N => 'L',
            .S => 'F',
            .E => '-',
            .W => '-',
        },
    };
}

fn connects_to(ch: u8, dir: Dir) ?Dir {
    return switch (dir) {
        .N => switch (ch) {
            '|' => .N,
            '7' => .W,
            'F' => .E,
            else => null,
        },
        .S => switch (ch) {
            '|' => .S,
            'L' => .E,
            'J' => .W,
            else => null,
        },
        .E => switch (ch) {
            '-' => .E,
            '7' => .S,
            'J' => .N,
            else => null,
        },
        .W => switch (ch) {
            '-' => .W,
            'L' => .N,
            'F' => .S,
            else => null,
        },
    };
}

fn valid_coord(grid: [][]const u8, coord: [2]isize) bool {
    return coord[0] >= 0 and coord[1] >= 0 and coord[0] < grid.len and coord[1] < grid[0].len;
}

fn grid_get(grid: [][]const u8, coord: [2]isize) u8 {
    return grid[@intCast(coord[0])][@intCast(coord[1])];
}

fn grid_set(grid: [][]u8, coord: [2]isize, ch: u8) void {
    grid[@intCast(coord[0])][@intCast(coord[1])] = ch;
}

pub fn main() !void {
    const input = try getInput();
    var grid_arr = std.ArrayList([]u8).init(m);
    var map_arr = std.ArrayList([]u8).init(m);
    var line_it = strTokLine(input);
    var start: [2]isize = undefined;
    var r: isize = 0;
    var c: isize = 0;
    while (line_it.next()) |line| {
        const grid_line = try m.alloc(u8, line.len);
        @memcpy(grid_line, line);
        try grid_arr.append(grid_line);
        const map_line = try m.alloc(u8, line.len);
        @memset(map_line, '0');
        try map_arr.append(map_line);
        c = 0;
        for (line) |ch| {
            if (ch == 'S') {
                start = .{ r, c };
                break;
            }
            c += 1;
        }
        r += 1;
    }
    const grid = grid_arr.items;
    const map = map_arr.items;
    var prev_dir: Dir = undefined;
    var curr: [2]isize = undefined;
    r = -1;
    find_first: while (r < 2) : (r += 1) {
        c = -1;
        while (c < 2) : (c += 1) {
            if (r == 0 and c == 0) {
                continue;
            }
            if (r != 0 and c != 0) {
                continue;
            }
            const p = .{ start[0] + r, start[1] + c };
            if (!valid_coord(grid, p)) {
                continue;
            }
            const ch = grid_get(grid, p);
            const dir = Dir.from_offset(.{ r, c });
            //print("{c}, {any}, {any}\n", .{ ch, dir, .{ r, c } });
            if (connects_to(ch, dir) == null) {
                continue;
            }
            curr = p;
            prev_dir = dir;
            break :find_first;
        }
    }
    for (grid) |row| {
        _ = row;

        //print("{s}\n", .{row});
    }
    const first_dir = prev_dir;
    while (true) {
        //print("curr: {any}, prev_dir: {any}\n", .{ curr, prev_dir });
        const ch = grid_get(grid, curr);
        grid_set(map, curr, '1');
        if (connects_to(ch, prev_dir)) |next_dir| {
            prev_dir = next_dir;
            const off = prev_dir.to_offset();
            curr = .{ curr[0] + off[0], curr[1] + off[1] };
        } else {
            if (ch == 'S') {
                grid_set(grid, curr, dirs_to_ch(prev_dir, first_dir));
                break;
            } else {
                unreachable;
            }
        }
    }
    for (map) |row| {
        _ = row;

        //print("{s}\n", .{row});
    }
    var count: usize = 0;
    r = 0;
    while (r < grid.len) : (r += 1) {
        var parity: usize = 0;
        c = 0;
        while (c < grid[0].len) : (c += 1) {
            const coord = .{ r, c };
            const ch = grid_get(grid, coord);
            //print("{any}, {c}\n", .{ coord, ch });
            if (grid_get(map, coord) == '1') {
                switch (ch) {
                    '|', 'F', '7' => parity += 1,
                    '-', 'J', 'L' => continue,
                    else => unreachable,
                }
                parity = parity % 2;
            } else {
                if (parity == 1) {
                    count += 1;
                }
            }
        }
    }

    //print("start: {any}\n", .{start});
    print("{}\n", .{count});
}
