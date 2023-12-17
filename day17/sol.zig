const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

const Dir = enum(u8) {
    N = 1,
    W = 2,
    S = 3,
    E = 4,
};

const Snoo = struct {
    p: [2]usize,
    n: usize, // num in same dir
    d: Dir, // dir to get here
};

fn compare(dist: *std.AutoHashMap(Snoo, usize), a: Snoo, b: Snoo) std.math.Order {
    return std.math.order(dist.get(a).?, dist.get(b).?);
}

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var line_it = util.strTokLine(input);
    var grid_arr = std.ArrayList([]usize).init(m);

    while (line_it.next()) |line| {
        var row = try m.alloc(usize, line.len);
        for (line, 0..) |ch, c| {
            row[c] = ch - '0';
        }
        try grid_arr.append(row);
    }
    const grid = grid_arr.items;

    var explored = std.AutoHashMap([2]usize, Snoo).init(m);
    var dist = std.AutoHashMap(Snoo, usize).init(m);
    var queue = std.PriorityQueue(Snoo, *@TypeOf(dist), compare).init(m, &dist);
    var prev = std.AutoHashMap(Snoo, ?Snoo).init(m);
    const end_pos: [2]usize = .{ grid.len - 1, grid[0].len - 1 };
    const start_E: Snoo = .{
        .p = .{ 0, 0 },
        .n = 0,
        .d = .E,
    };
    const start_S: Snoo = .{
        .p = .{ 0, 0 },
        .n = 0,
        .d = .S,
    };
    var end: Snoo = undefined;
    try dist.put(start_E, 0);
    try dist.put(start_S, 0);
    try queue.add(start_E);
    try queue.add(start_S);
    try prev.put(start_E, null);
    try prev.put(start_S, null);
    while (queue.len > 0) {
        const curr = queue.remove();
        //print("curr {any}\n", .{curr});
        try explored.put(curr.p, curr);
        if (curr.p[0] == end_pos[0] and curr.p[1] == end_pos[1]) {
            total = dist.get(curr).?;
            end = curr;
            break;
        }
        for ([_]Dir{ .N, .W, .S, .E }) |d| {
            var next_p = curr.p;
            switch (d) {
                .N => if (curr.p[0] == 0 or curr.d == .S) continue else {
                    next_p[0] -= 1;
                },
                .W => if (curr.p[1] == 0 or curr.d == .E) continue else {
                    next_p[1] -= 1;
                },
                .S => if (curr.p[0] == grid.len - 1 or curr.d == .N) continue else {
                    next_p[0] += 1;
                },
                .E => if (curr.p[1] == grid[0].len - 1 or curr.d == .W) continue else {
                    next_p[1] += 1;
                },
            }
            var n: usize = 1;
            if (curr.d == d) {
                n = curr.n + 1;
            }

            if (n > 3) {
                continue;
            }
            //if (explored.get(next_p)) |_| {
            //    continue;
            //}
            const next: Snoo = .{
                .p = next_p,
                .n = n,
                .d = d,
            };

            var add: bool = true;
            const g = dist.get(curr).? + grid[next_p[0]][next_p[1]];
            if (dist.get(next)) |best_dist| {
                if (g >= best_dist) {
                    add = false;
                }
            }

            if (add) {
                //print("add {any}, g {}\n", .{ next, g });
                try prev.put(next, curr);
                try dist.put(next, g);
                try queue.add(next);
            }
        }
    }
    //var it = prev.iterator();
    //while (it.next()) |a| {
    //    print("{any} -> {any}\n", .{ a.value_ptr.*, a.key_ptr.* });
    //}
    //total = dist.get(end_pos).?;

    var path_pts = std.AutoHashMap([2]usize, usize).init(m);
    var path = std.ArrayList([2]usize).init(m);
    var curr = end;
    while (!(curr.p[0] == 0 and curr.p[1] == 0)) {
        try path.append(curr.p);
        try path_pts.put(curr.p, undefined);
        //total += grid[curr[0]][curr[1]];
        print("PATH {}\n", .{curr});
        const pre = prev.get(curr).?;
        if (pre) |preee| {
            curr = preee;
        } else {
            break;
        }
    }

    for (grid, 0..) |row, r| {
        for (row, 0..) |n, c| {
            const p = .{ r, c };
            if (path_pts.get(p)) |_| {
                print("#", .{});
            } else {
                print("{}", .{n});
            }
        }
        print("\n", .{});
    }
    print("\n", .{});

    if (part2) {}

    return total;
}

pub fn main() !void {
    const input = try util.getInput();
    print("{}\n", .{try solve(input, false)});
    //print("{}\n", .{try solve(input, true)});
}
