const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const HM = std.AutoHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

const In = struct {
    dir: u8,
    num: i32,
};

const dirs: [4][2]i32 = .{
    .{ 0, 1 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ -1, 0 },
};

fn solve(input: []const u8, part2: bool) !u64 {
    var line_it = u.strTokLine(input);
    var ins_arr = AL(In).init(heap);
    var verts = AL([2]i64).init(heap);

    while (line_it.next()) |line| {
        var it = u.strTokAny(line, " ()#");
        const dir_p1: u8 = switch (it.next().?[0]) {
            'U' => 3,
            'L' => 2,
            'D' => 1,
            'R' => 0,
            else => unreachable,
        };
        const num_p1: i32 = try parseInt(i32, it.next().?, 10);
        const p2ins = it.next().?;
        const num_p2: i32 = try parseInt(i32, p2ins[0..5], 16);
        const dir_p2: u8 = p2ins[5] - '0';
        if (part2) {
            try ins_arr.append(.{
                .dir = dir_p2,
                .num = num_p2,
            });
        } else {
            try ins_arr.append(.{
                .dir = dir_p1,
                .num = num_p1,
            });
        }
    }
    const start: [2]i64 = .{ 0, 0 };
    var edge_count: u64 = 0;
    var min = start;
    var max = start;
    {
        var curr = start;
        for (ins_arr.items) |ins| {
            const dir = dirs[ins.dir];
            for (0..2) |i| {
                curr[i] += dir[i] * ins.num;
                min[i] = @min(min[i], curr[i]);
                max[i] = @max(max[i], curr[i]);
            }
            try verts.append(curr);
            edge_count += @abs(ins.num);
        }
    }
    //print("min {any}, max {any}\n", .{ min, max });
    //for (verts.items) |v| {
    //    print("{any}\n", .{v});
    //}
    //print("{any}\n", .{ins_arr.items});
    var in_count: i64 = 0;
    for (0..verts.items.len) |i| {
        const vi = verts.items[i];
        const vj = verts.items[(i + 1) % verts.items.len];
        in_count += (vi[0] + vj[0]) * (vi[1] - vj[1]);
    }
    //print("in {}, edge {}\n", .{ in_count, edge_count });
    var count: u64 = @abs(in_count);
    count = @divTrunc(count, 2);
    count += @divTrunc(edge_count, 2);
    count += 1;

    return count;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
