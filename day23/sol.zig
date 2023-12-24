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

const SeenMap = std.AutoArrayHashMap(NodeId, void);
const StackEl = struct { node: NodeId, len: usize, done_fork: bool };

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

fn findNewNode(grid: [][]const u8, start: [2]usize, dir: Dir, part2: bool) ?struct { node: Node, len: usize } {
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
                    if (!part2 and d == n.dir.opp()) { // can't move onto opp direction arrow from neighbor direction
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
                    else => if (!part2 and n.ch != n.dir.toCh()) {
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

fn solve(input: []const u8, part2: bool) !usize {
    const total: usize = 0;
    _ = total;
    var line_it = u.strTokLine(input);
    var grid_arr = AL([]const u8).init(heap);

    while (line_it.next()) |line| {
        try grid_arr.append(line);
    }
    const grid = try grid_arr.toOwnedSlice();
    const start_pos: [2]usize = .{ 0, 1 };
    const end_pos: [2]usize = .{ grid.len - 1, grid[0].len - 2 };
    var end_id: NodeId = undefined;
    // explore to get node list
    var start = Node{
        .pos = start_pos,
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
    var node_ids = AL(NodeId).init(heap);
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
            if (findNewNode(grid, neighbor.pos, neighbor.dir, part2)) |nn| {
                neighbor.len = nn.len;
                neighbor.pos = nn.node.pos;
                if (node_map.get(nn.node.pos)) |nn_id| {
                    neighbor.node = nn_id;
                } else {
                    const nn_id = node_list.items.len;
                    neighbor.node = nn_id;
                    try node_ids.append(nn_id);
                    try node_list.append(nn.node);
                    try node_map.put(nn.node.pos, nn_id);
                    try unfinished_nodes.append(nn_id);
                    if (std.mem.eql(usize, &nn.node.pos, &end_pos)) {
                        end_id = nn_id;
                    }
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
    if (false) {
        for (node_list.items, 0..) |*node, i| {
            print("{}: {any}\n", .{ i, node.pos });
            for (node.neighbors.slice()) |neighbor| {
                print("  {any}\n", .{neighbor});
            }
        }
        if (part2) assert(false);
    }

    // DFS stack
    var seen = SeenMap.init(heap);
    var stack = AL(StackEl).init(heap);
    var max_path_len: usize = 0;
    try stack.append(.{
        .node = 0,
        .len = 0,
        .done_fork = false,
    });

    while (stack.items.len > 0) {
        var curr = stack.pop();

        if (curr.done_fork) {
            assert(seen.swapRemove(curr.node));
            continue;
        }
        if (curr.node == end_id) {
            //print("found end with path len {}\n\n", .{len});
            max_path_len = @max(curr.len, max_path_len);
            continue;
        }
        if (seen.contains(curr.node)) {
            continue;
        }
        try seen.put(curr.node, undefined);
        // mark end of exploring this fork
        curr.done_fork = true;
        try stack.append(curr);

        // explore this fork
        var curr_node = node_list.items[curr.node];
        for (curr_node.neighbors.slice()) |n| {
            if (seen.contains(n.node.?)) {
                continue;
            }
            //print("  {any}\n", .{n});
            //if (curr.seen.contains(n.node.?)) continue;
            const next = .{ .node = n.node.?, .len = curr.len + n.len, .done_fork = false };
            try stack.append(next);
        }
    }

    return max_path_len;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
