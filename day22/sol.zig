const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const HM = std.AutoHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

const Id = i32;
const MapType = std.AutoArrayHashMap(Id, struct { a: [3]usize, b: [3]usize });

var next_id: Id = 0;

fn id_to_ch(id: Id) u8 {
    if (next_id + 'A' > 'Z') {
        return '?';
    }
    return 'A' + @as(u8, @intCast(id));
}

fn printAxis(grid: [][][]Id, axis: usize, depth: usize) void {
    switch (axis) {
        0 => {
            assert(false);
        },
        1 => {
            var z: usize = grid.len - 1;
            for (0..grid[0][0].len) |x| {
                print("{}", .{x});
            }
            print("\n", .{});
            while (z > 0) : (z -= 1) {
                for (0..grid[0][0].len) |x| {
                    const id = grid[z][depth][x];
                    const ch = if (id == -1) '.' else id_to_ch(id);
                    print("{c}", .{ch});
                }
                print(" {}\n", .{z});
            }
            for (0..grid[0][0].len) |_| {
                print("-", .{});
            }
            print(" 0\n", .{});
        },
        2 => {
            assert(false);
        },
        else => unreachable,
    }
}

// brick_removed must support supported_brick
fn supported(map: MapType, grid: [][][]Id, supported_brick: Id, removed_map: *std.AutoArrayHashMap(Id, void)) bool {
    const above_v = map.get(supported_brick).?;
    const min_z = above_v.a[0];
    assert(min_z > 1);
    for (above_v.a[1]..above_v.b[1]) |y| {
        for (above_v.a[2]..above_v.b[2]) |x| {
            const below_id = grid[min_z - 1][y][x];
            assert(below_id != supported_brick);
            if (below_id == -1 or removed_map.contains(below_id)) {
                continue;
            }
            return true;
        }
    }
    return false;
}

fn num_fall(map: MapType, grid: [][][]Id, brick_removed: Id, removed_map: *std.AutoArrayHashMap(Id, void)) !usize {
    var supports = std.AutoArrayHashMap(Id, void).init(heap);
    defer (supports.deinit());
    var total: usize = 0;
    const v = map.get(brick_removed).?;
    const above_z = v.b[0];

    if (above_z >= grid.len) {
        return 0;
    }
    assert(above_z > 1);

    //print("try remove {c}, above_z: {}\n", .{ id_to_ch(k), above_z });
    for (v.a[1]..v.b[1]) |y| {
        for (v.a[2]..v.b[2]) |x| {
            const above_id = grid[above_z][y][x];
            //print("{} {} {}\n", .{ above_z, y, x });
            assert(above_id != brick_removed);
            if (above_id == -1) {
                continue;
            }
            //print("  {c} supports {c}\n", .{ id_to_ch(k), id_to_ch(above_id) });
            try supports.put(above_id, undefined);
        }
    }
    if (supports.count() == 0) {
        return 0;
    }
    try removed_map.put(brick_removed, undefined);
    for (supports.keys()) |supported_k| {
        if (!supported(map, grid, supported_k, removed_map)) {
            total += try num_fall(map, grid, supported_k, removed_map) + 1;
        }
    }

    return total;
}

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var map = MapType.init(heap);

    var line_it = u.strTokLine(input);
    //var grid_arr = std.ArrayList()
    var min: [3]usize = .{ 99999, 99999, 99999 };
    var max: [3]usize = .{ 0, 0, 0 };
    while (line_it.next()) |line| {
        var ab_it = u.strTokAny(line, "~,");
        const id = next_id;
        next_id += 1;
        var a: [3]usize = .{
            try parseInt(usize, ab_it.next().?, 10),
            try parseInt(usize, ab_it.next().?, 10),
            try parseInt(usize, ab_it.next().?, 10),
        };
        std.mem.reverse(usize, &a);
        var b: [3]usize = .{
            try parseInt(usize, ab_it.next().?, 10) + 1,
            try parseInt(usize, ab_it.next().?, 10) + 1,
            try parseInt(usize, ab_it.next().?, 10) + 1,
        };
        std.mem.reverse(usize, &b);
        for (a, b, 0..) |c_a, c_b, i| {
            assert(c_a <= c_b);
            min[i] = @min(min[i], c_a);
            max[i] = @max(max[i], c_b);
        }
        try map.put(id, .{ .a = a, .b = b });
    }
    //print("min: {any}\nmax: {any}\n", .{ min, max });
    //print("max mul: {}\n", .{max[0] * max[1] * max[2]});
    // REMEMBER Z, Y, X
    var grid: [][][]Id = try heap.alloc([][]Id, max[0]);
    for (0..max[0]) |z| {
        var ymem = try heap.alloc([]Id, max[1]);
        for (0..max[1]) |y| {
            const xmem = try heap.alloc(Id, max[2]);
            @memset(xmem, -1);
            ymem[y] = xmem;
        }
        grid[z] = ymem;
    }
    //print("grid size: {} {} {}\n", .{ grid.len, grid[0].len, grid[0][0].len });
    var mass: usize = 0;
    for (map.keys()) |k| {
        const v = map.get(k).?;
        for (v.a[0]..v.b[0]) |z| {
            for (v.a[1]..v.b[1]) |y| {
                for (v.a[2]..v.b[2]) |x| {
                    assert(grid[z][y][x] == -1);
                    grid[z][y][x] = k;
                    mass += 1;
                }
            }
        }
    }
    // fall
    //printAxis(grid, 1, 2);
    while (true) {
        var moves: usize = 0;
        block: for (map.keys()) |k| {
            var v = map.getPtr(k).?;
            assert(v.a[0] <= v.b[0]);
            const min_z = v.a[0];
            assert(min_z > 0);
            if (min_z == 1) {
                continue;
            }
            //print("try falling {c}\n", .{id_to_ch(k)});
            for (v.a[1]..v.b[1]) |y| {
                for (v.a[2]..v.b[2]) |x| {
                    const below_id = grid[min_z - 1][y][x];
                    assert(below_id != k);
                    if (below_id != -1) {
                        continue :block;
                    }
                }
            }
            //print("{c} fell\n", .{id_to_ch(k)});
            moves += 1;
            for (v.a[0]..v.b[0]) |z| {
                for (v.a[1]..v.b[1]) |y| {
                    for (v.a[2]..v.b[2]) |x| {
                        assert(grid[z][y][x] == k);
                        assert(grid[z - 1][y][x] == -1);
                        grid[z - 1][y][x] = k;
                        grid[z][y][x] = -1;
                    }
                }
            }
            v.a[0] -= 1;
            v.b[0] -= 1;
        }

        if (moves == 0) {
            break;
        }
    }
    // check mass is same after falling, and all bricks are supported
    var new_mass: usize = 0;
    for (map.keys()) |k| {
        var num_supports: usize = 0;
        const v = map.get(k).?;
        const min_z = v.a[0];
        //print("{c} min_z = {}\n", .{ id_to_ch(k), min_z });
        for (v.a[0]..v.b[0]) |z| {
            _ = z;
            for (v.a[1]..v.b[1]) |y| {
                for (v.a[2]..v.b[2]) |x| {
                    if (min_z > 1) {
                        const below_id = grid[min_z - 1][y][x];
                        if (below_id != -1 and below_id != k) {
                            num_supports += 1;
                        }
                    }
                    new_mass += 1;
                }
            }
        }
        if (min_z > 1 and num_supports == 0) {
            //print("{c} has no supports!\n", .{id_to_ch(k)});
            assert(false);
        }
    }
    assert(mass == new_mass);
    //printAxis(grid, 1, 0);
    //printAxis(grid, 1, 1);
    //printAxis(grid, 1, 2);
    var removed_map = std.AutoArrayHashMap(Id, void).init(heap);
    if (part2) {
        for (map.keys()) |k| {
            removed_map.clearRetainingCapacity();
            const num = try num_fall(map, grid, k, &removed_map);
            //print("removing {c} would cause {} to fall\n", .{ id_to_ch(k), num });
            total += num;
        }
    } else {
        for (map.keys()) |k| {
            removed_map.clearRetainingCapacity();
            if (try num_fall(map, grid, k, &removed_map) == 0) {
                total += 1;
            }
        }
    }

    return total;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
