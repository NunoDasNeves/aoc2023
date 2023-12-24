const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const HM = std.AutoHashMap;
const AAHM = std.AutoArrayHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

const StackEl = struct { p: [2]usize, fork_num: usize, is_fork: bool };
const SeenMap = std.AutoArrayHashMap([2]usize, void);

const Dir = enum(u8) {
    pub const all = [_]Dir{ .N, .W, .S, .E };
    pub const chs = [_]u8{ '^', '<', 'v', '>' };

    N = 0,
    W = 1,
    S = 2,
    E = 3,

    pub fn opp(self: @This()) @This() {
        return @enumFromInt((@intFromEnum(self) + 2) % 4);
    }
    pub fn toCh(self: @This()) u8 {
        return chs[@intFromEnum(self)];
    }
    pub fn fromCh(ch: u8) ?@This() {
        return switch (ch) {
            '^' => .N,
            '<' => .W,
            'v' => .S,
            '>' => .E,
            else => null,
        };
    }
};

const NodeId = usize;
const Neighbor = struct {
    node: ?NodeId = null,
    len: usize,
    dir: Dir,
    pos: [2]usize,
    ch: u8,
};
const Node = struct {
    pos: [2]usize,
    neighbors: u.StaticBuf(Neighbor, 4),
};
const NodeList = AL(Node);

fn getNeighbors(grid: [][]const u8, pos: [2]usize) u.StaticBuf(Neighbor, 4) {
    var ret = u.StaticBuf(Neighbor, 4){};
    for (Dir.all) |d| {
        var next = pos;
        switch (d) {
            .N => if (pos[0] == 0) continue else {
                next[0] -= 1;
            },
            .W => if (pos[1] == 0) continue else {
                next[1] -= 1;
            },
            .S => if (pos[0] == grid.len - 1) continue else {
                next[0] += 1;
            },
            .E => if (pos[1] == grid[0].len - 1) continue else {
                next[1] += 1;
            },
        }
        const ch = grid[next[0]][next[1]];
        switch (ch) {
            '.' => {},
            else => {}, // keep neighbors that go in 'wrong' direction still for now
            '#' => continue,
        }
        assert(ret.append(.{
            .dir = d,
            .pos = next,
            .ch = ch,
            .len = 0,
        }));
    }
    return ret;
}

fn findNewNode(grid: [][]const u8, start: [2]usize, dir: Dir) ?struct { node: Node, len: usize } {
    var curr_p = start;
    var curr_dir = dir;
    var path_len: usize = 1;

    while (true) {
        var neighbors = getNeighbors(grid, curr_p);
        if (neighbors.len == 2) {
            for (neighbors.slice()) |n| {
                if (n.dir == curr_dir.opp()) { // don't go backwards
                    continue;
                } else if (Dir.fromCh(n.ch)) |d| {
                    if (d == n.dir.opp()) { // can't move onto opp direction arrow from neighbor direction
                        return null;
                    }
                }
                curr_p = n.pos;
                curr_dir = n.dir;
                path_len += 1;
                break;
            }
        } else {
            var i: usize = 0;
            while (i < neighbors.len) {
                const n = neighbors.buf[i];
                switch (n.ch) {
                    '.' => {},
                    '#' => unreachable,
                    else => if (n.ch != n.dir.toCh()) {
                        _ = neighbors.swapRemove(i);
                        continue;
                    },
                }
                i += 1;
            }
            return .{ .node = .{ .pos = curr_p, .neighbors = neighbors }, .len = path_len };
        }
    }
    unreachable;
}

fn printSeen(grid: [][]const u8, seen: SeenMap) void {
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

    { // explore to get node list
        var start = Node{
            .pos = .{ 0, 1 },
            .neighbors = .{},
        };
        assert(start.neighbors.append(.{
            .node = null,
            .len = 0,
            .dir = .S,
            .pos = .{ 1, 1 },
            .ch = '.',
        }));
        var node_list = NodeList.init(heap);
        var node_map = AAHM([2]usize, NodeId).init(heap);
        var unfinished_nodes = AL(NodeId).init(heap);
        try node_list.append(start);
        try node_map.put(start.pos, 0);
        try unfinished_nodes.append(0);

        while (unfinished_nodes.items.len > 0) {
            const curr_id = unfinished_nodes.pop();
            var curr = node_list.items[curr_id];
            var i: usize = 0;
            while (i < curr.neighbors.len) {
                var neighbor = &curr.neighbors.buf[i];
                if (neighbor.node) |_| continue;
                if (findNewNode(grid, neighbor.pos, neighbor.dir)) |nn| {
                    neighbor.len = nn.len;
                    neighbor.pos = nn.node.pos;
                    if (node_map.get(nn.node.pos)) |nn_id| {
                        neighbor.node = nn_id;
                    } else {
                        const nn_id = node_list.items.len;
                        neighbor.node = nn_id;
                        try node_list.append(nn.node);
                        try node_map.put(nn.node.pos, nn_id);
                        try unfinished_nodes.append(nn_id);
                    }
                    i += 1;
                } else {
                    _ = curr.neighbors.swapRemove(i);
                    continue;
                }
            }
            // node is finished, update it
            node_list.items[curr_id] = curr;
        }
        for (node_list.items, 0..) |*node, i| {
            print("{}: {any}\n", .{ i, node.pos });
            for (node.neighbors.slice()) |neighbor| {
                print("  {any}\n", .{neighbor});
            }
        }
    }
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
                //printSeen(grid, seen_map);
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
                //printSeen(grid, seen_map);
            }
            // start a new fork
            try fork_len_stack.append(0);
            fork_num = curr.fork_num;
            //printSeen(grid, seen_map);
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

        var to_append = u.StaticBuf([2]usize, 4){};
        const curr_ch = grid[curr.p[0]][curr.p[1]];
        const ds: []const Dir = blk: {
            if (part2) {
                break :blk Dir.all[0..];
            } else {
                break :blk switch (curr_ch) {
                    '^' => ([_]Dir{.N})[0..],
                    '<' => ([_]Dir{.W})[0..],
                    'v' => ([_]Dir{.S})[0..],
                    '>' => ([_]Dir{.E})[0..],
                    else => Dir.all[0..],
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
            for (to_append.slice()) |next| {
                //print("  {any} {c} \n", .{ next, grid[next[0]][next[1]] });
                try stack.append(.{ .p = next, .fork_num = fork_num + 1, .is_fork = true });
            }
        } else if (to_append.len > 0) {
            try stack.append(.{ .p = to_append.buf[0], .fork_num = fork_num, .is_fork = false });
        }
    }

    return max_path_len - 1;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
