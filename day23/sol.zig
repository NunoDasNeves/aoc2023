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

const StackEl = struct { p: [2]usize, fork_num: usize, is_fork: bool };
const SeenMap = std.AutoArrayHashMap([2]usize, void);

const Dir = enum {
    N,
    W,
    S,
    E,
};
const dirs = [_]Dir{ .N, .W, .S, .E };

fn print_seen(grid: [][]const u8, seen: SeenMap) void {
    for (grid, 0..) |row, r| {
        for (row, 0..) |ch, c| {
            const p = .{ r, c };
            if (seen.contains(p)) {
                print("O", .{});
            } else {
                print("{c}", .{ch});
            }
        }
        print("\n", .{});
    }
}

fn solve(input: []const u8, part2: bool) !usize {
    const total: usize = 0;
    _ = total;
    var line_it = u.strTokLine(input);
    var grid_arr = AL([]const u8).init(heap);

    while (line_it.next()) |line| {
        try grid_arr.append(line);
    }
    const grid = try grid_arr.toOwnedSlice();
    const start: [2]usize = .{ 0, 1 };
    const end: [2]usize = .{ grid.len - 1, grid[0].len - 2 };

    // DFS stack
    var stack = AL(StackEl).init(heap);
    // stack of all places visited in the currently exploring path. len == curr path len
    var seen_stack = AL([2]usize).init(heap);
    // stack of fork path lens, used to pop seen stack
    var fork_len_stack = AL(usize).init(heap);
    // everything seen, popped from when a fork is popped
    var seen_map = SeenMap.init(heap);
    var max_path_len: usize = 0;
    var fork_num: usize = 0;
    try fork_len_stack.append(0);
    try stack.append(.{ .p = start, .fork_num = 0, .is_fork = false });

    while (stack.items.len > 0) {
        const curr = stack.pop();
        if (curr.is_fork) {
            if (curr.fork_num > fork_num) {
                //print("found new fork: {}, {any}, {c}\n", .{ curr.fork_num, curr.p, grid[curr.p[0]][curr.p[1]] });
            } else {
                //print("trying another fork: {}, {any}, {c}\n", .{ curr.fork_num, curr.p, grid[curr.p[0]][curr.p[1]] });
                //print("before:\n", .{});
                //print("fork_lens: {any}\n", .{fork_len_stack.items});
                //print_seen(grid, seen_map);
                const num_forks_to_pop = fork_num - curr.fork_num + 1;
                for (0..num_forks_to_pop) |_| {
                    const fork_len = fork_len_stack.pop();
                    for (0..fork_len) |_| {
                        const p = seen_stack.pop();
                        assert(seen_map.swapRemove(p));
                    }
                }
                //print("after:\n", .{});
                //print("fork_lens: {any}\n", .{fork_len_stack.items});
                //print_seen(grid, seen_map);
            }
            // start a new fork
            try fork_len_stack.append(0);
            fork_num = curr.fork_num;
            //print_seen(grid, seen_map);
            //print("\n", .{});
        }
        // continue the fork
        try seen_map.put(curr.p, undefined);
        try (seen_stack.append(curr.p));
        fork_len_stack.items[fork_len_stack.items.len - 1] += 1;

        if (std.mem.eql(usize, &curr.p, &end)) {
            //print("found end with path len {}\n\n", .{seen_stack.items.len});
            max_path_len = @max(seen_stack.items.len, max_path_len);
            continue;
        }

        var to_append = u.StaticBuf([4][2]usize){};
        const curr_ch = grid[curr.p[0]][curr.p[1]];
        const ds: []const Dir = blk: {
            if (part2) {
                break :blk dirs[0..];
            } else {
                break :blk switch (curr_ch) {
                    '^' => ([_]Dir{.N})[0..],
                    '<' => ([_]Dir{.W})[0..],
                    'v' => ([_]Dir{.S})[0..],
                    '>' => ([_]Dir{.E})[0..],
                    else => dirs[0..],
                };
            }
        };
        for (ds) |d| {
            var next = curr;
            switch (d) {
                .N => if (curr.p[0] == 0) continue else {
                    next.p[0] -= 1;
                },
                .W => if (curr.p[1] == 0) continue else {
                    next.p[1] -= 1;
                },
                .S => if (curr.p[0] == grid.len - 1) continue else {
                    next.p[0] += 1;
                },
                .E => if (curr.p[1] == grid[0].len - 1) continue else {
                    next.p[1] += 1;
                },
            }
            const next_ch = grid[next.p[0]][next.p[1]];
            if (next_ch == '#') {
                continue;
            }
            if (seen_map.get(next.p)) |_| {
                continue;
            }
            assert(to_append.append(next.p));
        }
        if (to_append.len > 1) {
            //print("forked\n", .{});
            for (to_append.buf()) |next| {
                //print("  {any} {c} \n", .{ next, grid[next[0]][next[1]] });
                try stack.append(.{ .p = next, .fork_num = fork_num + 1, .is_fork = true });
            }
        } else if (to_append.len > 0) {
            try stack.append(.{ .p = to_append.storage[0], .fork_num = fork_num, .is_fork = false });
        }
    }

    return max_path_len - 1;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
