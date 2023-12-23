const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const AAHM = std.AutoArrayHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

const dirs: [4][2]i64 = .{ .{ -1, 0 }, .{ 0, -1 }, .{ 1, 0 }, .{ 0, 1 } };

fn add(curr: [3]i64, dir: [2]i64) ![3]i64 {
    return .{ curr[0] + dir[0], curr[1] + dir[1], curr[2] + 1 };
}

fn do_mod(n: i64, m: usize) i64 {
    if (n < 0) {
        const mo: i64 = @intCast(@abs(n) % @as(u64, m));
        if (mo == 0) {
            return 0;
        } else {
            return @as(i64, @intCast(m)) - mo;
        }
    } else {
        return @mod(n, @as(i64, @intCast(m)));
    }
}

fn make_big_grid(grid: [][]const u8, E: AAHM([3]i64, void), num_steps: u64, big_grid_sz: u64) ![][]u64 {
    var big_grid_arr = AL([]u64).init(heap);
    for (0..big_grid_sz) |_| {
        const row = try heap.alloc(u64, big_grid_sz);
        @memset(row, 0);
        try big_grid_arr.append(row[0..]);
    }
    const big_grid_sz_2: i64 = @intCast(@divTrunc(big_grid_sz, 2));
    for (0..big_grid_sz) |i| {
        for (0..big_grid_sz) |j| {
            var count: u64 = 0;
            const s_ij: [2]i64 = .{ @as(i64, @intCast(i)) - big_grid_sz_2, @as(i64, @intCast(j)) - big_grid_sz_2 };
            const grid_off: [2]i64 = .{ @as(i64, @intCast(grid.len)) * s_ij[0], @as(i64, @intCast(grid[0].len)) * s_ij[1] };
            for (0..grid.len) |r| {
                for (0..grid[0].len) |c| {
                    const p = .{ grid_off[0] + @as(i64, @intCast(r)), grid_off[1] + @as(i64, @intCast(c)) };
                    if (E.get(.{ p[0], p[1], @intCast(num_steps) })) |_| {
                        count += 1;
                    }
                }
            }
            big_grid_arr.items[i][j] = count;
        }
    }
    return big_grid_arr.toOwnedSlice();
}

fn get_edge_features(big_grid: [][]u64, num_center_rings: usize) [4][3][3]u64 {
    const big_grid_sz = big_grid.len;
    const big_grid_sz_2: usize = @divTrunc(big_grid_sz, 2);
    const mid: [2]usize = .{ big_grid_sz_2, big_grid_sz_2 };
    var ret = std.mem.zeroes([4][3][3]u64);

    var dirposes: [4][2]usize = .{ mid, mid, mid, mid };

    // N
    ret[0][2][1] = 1; // will set to 0
    var pos: *[2]usize = &dirposes[0];
    pos[0] = mid[0] - num_center_rings;
    pos[0] -= 1;
    pos[1] -= 1;
    // W
    ret[1][1][2] = 1; // will set to 0
    pos = &dirposes[1];
    pos[1] = mid[1] - num_center_rings;
    pos[1] -= 1;
    pos[0] -= 1;
    // S
    ret[2][0][1] = 1; // will set to 0
    pos = &dirposes[2];
    pos[0] = mid[0] + num_center_rings;
    pos[0] -= 1;
    pos[1] -= 1;
    // E
    ret[3][1][0] = 1; // will set to 0
    pos = &dirposes[3];
    pos[1] = mid[1] + num_center_rings;
    pos[1] -= 1;
    pos[0] -= 1;

    for (dirposes, 0..) |dirpos, i| {
        for (0..3) |dr| {
            for (0..3) |dc| {
                const p: [2]usize = .{ dirpos[0] + dr, dirpos[1] + dc };
                if (ret[i][dr][dc] == 0) {
                    ret[i][dr][dc] = big_grid[p[0]][p[1]];
                } else { // set marked one to 0; that is a 'center' square counted separately
                    ret[i][dr][dc] = 0;
                }
            }
        }
    }
    return ret;
}

fn find_period_slooow(big_grids: [][][]u64, start_idx: usize, range: usize) !u64 {
    var pmap = AAHM([4][9]u64, u64).init(heap);
    const big_grid_sz = big_grids[0].len;
    const big_grid_sz_2: usize = @intCast(@divTrunc(big_grid_sz, 2));
    var period: u64 = 0;
    for (big_grids, start_idx..start_idx + range) |big_grid, step_count| {
        var hash: [4][9]u64 = undefined;
        for (&hash) |*h| {
            @memset(h[0..], 0);
        }
        const mid: [2]usize = .{ big_grid_sz_2, big_grid_sz_2 };
        var dirposes: [4][2]usize = .{ mid, mid, mid, mid };

        // N
        var pos: *[2]usize = &dirposes[0];
        while (big_grid[pos[0]][pos[1]] != 0) {
            pos[0] -= 1;
            if (pos[0] == 0) break;
        }
        pos[0] += 1;
        pos[1] -= 1;
        // W
        pos = &dirposes[1];
        while (big_grid[pos[0]][pos[1]] != 0) {
            pos[1] -= 1;
            if (pos[1] == 0) break;
        }
        pos[1] += 1;
        pos[0] -= 1;
        // S
        pos = &dirposes[2];
        while (big_grid[pos[0]][pos[1]] != 0) {
            pos[0] += 1;
            if (pos[0] == big_grid_sz - 1) break;
        }
        pos[0] -= 3;
        pos[1] -= 1;
        // E
        pos = &dirposes[3];
        while (big_grid[pos[0]][pos[1]] != 0) {
            pos[1] += 1;
            if (pos[1] == big_grid_sz - 1) break;
        }
        pos[1] -= 3;
        pos[0] -= 1;
        {
            for (dirposes, 0..) |dirpos, i| {
                var j: usize = 0;
                for (0..3) |dr| {
                    for (0..3) |dc| {
                        const p: [2]usize = .{ dirpos[0] + dr, dirpos[1] + dc };
                        hash[i][j] = big_grid[p[0]][p[1]];
                        j += 1;
                    }
                }
            }
            if (pmap.get(hash)) |prev_count| {
                period = step_count - prev_count;
                break;
            }
            try pmap.put(hash, step_count);
        }
    }
    return period;
}

fn solve(input: []const u8, num_steps: u64, part2: bool) !u64 {
    var line_it = u.strTokLine(input);
    var grid_arr = AL([]const u8).init(heap);
    var start: [3]i64 = undefined;
    {
        var r: usize = 0;
        while (line_it.next()) |line| {
            for (0..line.len) |c| {
                if (line[c] == 'S') {
                    start = .{ @intCast(r), @intCast(c), 0 };
                }
            }
            try grid_arr.append(line);
            r += 1;
        }
    }
    const grid = grid_arr.items;
    if (false) {
        var Q = AL([3]i64).init(heap);
        var E = AAHM([3]i64, void).init(heap);
        try Q.append(start);
        while (Q.items.len > 0) {
            const curr = Q.pop();
            if (E.get(curr)) |_| {
                continue;
            }
            try E.put(curr, undefined);
            for (dirs) |dir| {
                const next = .{ curr[0] + dir[0], curr[1] + dir[1], curr[2] + 1 };
                const mod: [2]i64 = .{ do_mod(next[0], grid.len), do_mod(next[1], grid[0].len) };
                if (grid[@intCast(mod[0])][@intCast(mod[1])] == '#') continue;
                if (next[2] <= num_steps and E.get(next) == null) {
                    try Q.append(next);
                }
                if (next[2] == num_steps) {
                    //print("next: {any}, mod: {any}\n", .{ next, mod });
                }
            }
        }
        for (E.keys()) |k| {
            if (k[2] == num_steps) {
                //total += 1;
            }
        }
        var i: i64 = -5;
        while (i < 6) : (i += 1) {
            var j: i64 = -5;
            while (j < 6) : (j += 1) {
                var a: usize = 0;
                const grid_off: [2]i64 = .{ @as(i64, @intCast(grid.len)) * @as(i64, @intCast(i)), @as(i64, @intCast(grid[0].len)) * @as(i64, @intCast(j)) };
                for (0..grid.len) |r| {
                    for (0..grid[0].len) |c| {
                        const p = .{ grid_off[0] + @as(i64, @intCast(r)), grid_off[1] + @as(i64, @intCast(c)) };
                        if (E.get(.{ p[0], p[1], @intCast(num_steps) })) |_| {
                            a += 1;
                        }
                    }
                }
                //print("grid[{}][{}] hit {}\n", .{ i, j, a });
                print(" {0:2} |", .{a});
            }
            print("\n-------------------------------------------------------", .{});
            print("\n", .{});
        }
    }

    //const grid_sz = @max(grid.len, grid[0].len);
    const max_num_steps = if (part2) (500) else num_steps;
    print("num steps: {}, max num steps: {}\n", .{ num_steps, max_num_steps });
    var Q = AL([3]i64).init(heap);
    defer Q.deinit();
    var E = AAHM([3]i64, void).init(heap);
    defer E.deinit();
    try Q.append(start);
    while (Q.items.len > 0) {
        const curr = Q.pop();
        if (E.get(curr)) |_| {
            continue;
        }
        try E.put(curr, undefined);
        for (dirs) |dir| {
            const next = .{ curr[0] + dir[0], curr[1] + dir[1], curr[2] + 1 };
            const mod: [2]i64 = .{ do_mod(next[0], grid.len), do_mod(next[1], grid[0].len) };
            if (grid[@intCast(mod[0])][@intCast(mod[1])] == '#') continue;
            if (next[2] <= max_num_steps and E.get(next) == null) {
                try Q.append(next);
            }
        }
    }
    print("done search\n", .{});

    // part 1 and small numbers of steps end here:
    if (!part2 or num_steps < max_num_steps) {
        var total: u64 = 0;
        for (E.keys()) |k| {
            if (k[2] == num_steps) {
                total += 1;
            }
        }
        return total;
    }

    // the rest is for the big'uns
    const start_idx = max_num_steps / 2;
    const range = max_num_steps / 2;
    print("generate big grids {} to {}\n", .{ start_idx, start_idx + range });
    var big_grids = AL([][]u64).init(heap);
    const big_grid_sz: u64 = 11;
    for (start_idx..start_idx + range, 0..) |i, j| {
        const big_grid = try make_big_grid(grid, E, i, big_grid_sz);
        try big_grids.append(big_grid);
        print(".", .{});
        if (j % 100 == 0) {
            print("\n", .{});
        }
    }
    print("\n", .{});

    if (false) {
        const period = try find_period_slooow(big_grids.items, start_idx, range);
        print("period: {}\n", .{period});
    }

    const big_grid_sz_2: usize = @intCast(@divTrunc(big_grid_sz, 2));
    const big_grids_last_idx = big_grids.items.len - 1;
    const big_grids_last_step_count = big_grids_last_idx + start_idx;
    const mid: [2]usize = .{ big_grid_sz_2, big_grid_sz_2 };

    var even_odd_center: [2]u64 = .{ 0, 0 };
    if (big_grids_last_step_count & 1 == 0) {
        even_odd_center[0] = big_grids.items[big_grids_last_idx][mid[0]][mid[1]];
        even_odd_center[1] = big_grids.items[big_grids_last_idx - 1][mid[0]][mid[1]];
    } else {
        even_odd_center[1] = big_grids.items[big_grids_last_idx][mid[0]][mid[1]];
        even_odd_center[0] = big_grids.items[big_grids_last_idx - 1][mid[0]][mid[1]];
    }
    print("even odd center: {any}\n", .{even_odd_center});

    var center_change_step_counts = u.StaticBuf([20]usize){};
    var num_rings = u.StaticBuf([20]usize){};
    var prev_num_center_squares: usize = 0;
    for (big_grids.items, start_idx..start_idx + range) |big_grid, step_count| {
        var total: usize = 0;
        var num_center_squares: usize = 0;
        var num_edge_squares: usize = 0;
        var total_center: usize = 0;
        var total_edge: usize = 0;
        var ring_start = mid;
        var in_center: bool = true;
        var num_center_rings: usize = 0;
        //var ring_num: usize = 1;
        var even_odd: usize = step_count & 1;
        while (ring_start[0] > 0) {
            //print("{any}\n", .{ring_start});
            var curr = ring_start;
            var ring_square_count: usize = 0;
            var ring_total: usize = 0;
            //print("even odd center: {}\n", .{even_odd_center[even_odd]});
            while (true) {
                const count = big_grid[curr[0]][curr[1]];
                ring_square_count += 1;
                ring_total += count;
                if (count != even_odd_center[even_odd]) {
                    in_center = false;
                }
                //print("{any}\n", .{curr});
                if (curr[0] == mid[0] and curr[1] == mid[1]) {
                    break;
                }
                if (curr[0] < mid[0] and curr[1] >= mid[1]) {
                    curr[0] += 1;
                    curr[1] += 1;
                } else if (curr[0] >= mid[0] and curr[1] > mid[1]) {
                    curr[0] += 1;
                    curr[1] -= 1;
                } else if (curr[0] > mid[0] and curr[1] <= mid[1]) {
                    curr[0] -= 1;
                    curr[1] -= 1;
                } else {
                    curr[0] -= 1;
                    curr[1] += 1;
                }
                if (curr[0] == ring_start[0] and curr[1] == ring_start[1]) {
                    break;
                }
            }
            //print("square_count: {}: in center: {}\n", .{ ring_square_count, in_center });
            if (in_center) {
                num_center_squares += ring_square_count;
                total_center += ring_total;
                num_center_rings += 1;
            } else if (ring_total > 0) {
                num_edge_squares += ring_square_count;
                total_edge += ring_total;
            }
            even_odd ^= 1;
            ring_start[0] -= 1;
        }
        if (step_count == num_steps) {
            for (0..big_grid.len) |r| {
                for (0..big_grid[0].len) |c| {
                    const count = big_grid[r][c];
                    total += count;
                    print(" {0:2}  ", .{count});
                }
                print("\n\n", .{});
            }
            print("{}: {}\n", .{ step_count, total });
            print("CENTER: {} in {} squares\n", .{ total_center, num_center_squares });
            print("EDGE: {} squares\n", .{num_edge_squares});
            print("========\n", .{});
        }
        if (num_center_squares != 1) {
            if (prev_num_center_squares != num_center_squares) {
                assert(num_rings.append(num_center_rings));
                assert(center_change_step_counts.append(step_count));
            }
            prev_num_center_squares = num_center_squares;
        }
    }
    print("{any}\n", .{center_change_step_counts.buf()});
    assert(center_change_step_counts.len >= 3);
    const last_idx = center_change_step_counts.len - 1;
    const buf = center_change_step_counts.buf();
    const diff1 = buf[last_idx] - buf[last_idx - 1];
    const diff2 = buf[last_idx - 1] - buf[last_idx - 2];
    assert(diff1 == diff2);
    const period = diff1;
    const period_base_step_count = buf[last_idx - 2]; // NOTE changed this
    const big_grid_period_base_idx = period_base_step_count - start_idx;
    const period_base_num_center_rings = num_rings.storage[last_idx - 2];
    print("period: {}\n", .{period});
    const num_steps_periodic = num_steps - period_base_step_count;
    const offset = num_steps_periodic % period;
    const div = @divTrunc(num_steps_periodic, period);
    print("div: {} rem: {}\n", .{ div, offset });
    const num_rings_in_num_steps = period_base_num_center_rings + div;
    const num_center_squares_in_num_steps = num_rings_in_num_steps * num_rings_in_num_steps + (num_rings_in_num_steps - 1) * (num_rings_in_num_steps - 1);
    const center_total_in_num_steps = blk: {
        // count squares alternating, excluding center (i.e. 'even' if you consider center coord to be 1)
        const inc = (num_rings_in_num_steps & 1);
        const x = num_rings_in_num_steps - inc;
        const num = x * x;
        // the count of the other squares will be the complement
        const num_other = num_center_squares_in_num_steps - num;
        //
        if (num_steps & 1 == 0) {
            break :blk num_other * even_odd_center[0] + num * even_odd_center[1]; // include center - 'even' count goes in center
        } else {
            break :blk num * even_odd_center[0] + num_other * even_odd_center[1];
        }
    };
    print("num rings in {} steps: {}\n", .{ num_steps, num_rings_in_num_steps });
    print("step_count of features: {}\n", .{period_base_step_count + offset});
    print("num center squares in {} steps: {}\n", .{ num_steps, num_center_squares_in_num_steps });
    print("center total in {} steps: {}\n", .{ num_steps, center_total_in_num_steps });

    // now we gotta total the edges!
    var edge_total: usize = 0;
    const big_grid = big_grids.items[big_grid_period_base_idx + offset];
    const edge_features = get_edge_features(big_grid, period_base_num_center_rings);
    if (false) {
        for (0..big_grid.len) |r| {
            for (0..big_grid[0].len) |c| {
                const count = big_grid[r][c];
                print(" {0:2}  ", .{count});
            }
            print("\n\n", .{});
        }
        print("features:\n", .{});
        for (edge_features) |f| {
            for (f) |row| {
                print("{any}\n", .{row});
            }
        }
    }
    // easier to add these manually...
    const n = edge_features[0];
    const w = edge_features[1];
    const s = edge_features[2];
    const e = edge_features[3];
    // add up 'center's which dont repeat
    // NS
    for (0..3) |i| {
        edge_total += n[i][1];
        edge_total += s[i][1];
    }
    // WE
    for (0..3) |i| {
        edge_total += w[1][i];
        edge_total += e[1][i];
    }
    // add up each of the 4 diamond edges by using the 3 on the 'side' of each feature
    const inner_row_count = (num_rings_in_num_steps - 1);

    // inner to outer rows
    for (0..3) |i| {
        // NE
        edge_total += n[2 - i][2] * (inner_row_count + i);
        // NW
        edge_total += n[2 - i][0] * (inner_row_count + i);
        // SE
        edge_total += s[i][2] * (inner_row_count + i);
        // SW
        edge_total += s[i][0] * (inner_row_count + i);
    }

    //return 0;
    return edge_total + center_total_in_num_steps;
}

// num rings -> num center squares:
// 1,          5,            13,            25,           41
// 1^2 + 0^2,  2^2 + 1^2,    3^2 + 2^2,     4^2 + 3^2,    5^2 + 4^2
// n^2 + (n-1)^2
//
// num rings in num_steps:
// period_base_num_center_rings + ((num_steps - period_base_step_count) // period)
//
// num_rings -> center total (where repeating pattern is 0,1):
// num_rings   1,      2,     3,     4,      5,
// num_center  1,      5,    13,    25,     41,
// even        0,      4,     4,    16,     16,
// even_f      0^2,  2^2,   2^2,   4^4,     4^4,
// = ( num_rings - (num_rings & 1) ) ^ 2
// odd         1,      1,     9,     9,     25,
// odd_f       1^1,  1^1,   3^3,   3^3,     5^5
// = ( num_rings - ((num_rings & 1) xor 1) ) ^ 2
// = count excl center (even) = (num_rings - (num_rings & 1)) ^ 2

pub fn main() !void {
    const input = try u.getInput();
    //print("{}\n", .{try solve(input, 64, false)});

    // test inputs:
    if (false) {
        print("{}\n", .{try solve(input, 6, true)});
        print("{}\n", .{try solve(input, 10, true)});
        print("{}\n", .{try solve(input, 50, true)});
        print("{}\n", .{try solve(input, 100, true)});
        print("{}\n", .{try solve(input, 500, true)});
        print("{}\n", .{try solve(input, 1000, true)});
        print("{}\n", .{try solve(input, 5000, true)});
    }

    print("{}\n", .{try solve(input, 26501365, true)});
}
