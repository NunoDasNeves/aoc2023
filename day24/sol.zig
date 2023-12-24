const std = @import("std");
const assert = std.debug.assert;
const stdprint = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;
const AL = std.ArrayList;
const HM = std.AutoHashMap;
const ascii = std.ascii;

const u = @import("util.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const heap = gpa.allocator();

const test_test_range = [2]f64{ 7, 27 };
const real_test_range = [2]f64{ 200000000000000, 400000000000000 };
const eps = std.math.floatEps(f64);

const H = struct {
    p: [3]f64,
    v: [3]f64,
};

var do_print: bool = false;
fn print(comptime fmt: []const u8, args: anytype) void {
    if (!do_print) {
        return;
    }
    stdprint(fmt, args);
}

fn hailstones_intersect(a: H, b: H, test_range: [2]f64) bool {
    print("test:\n{any}\n{any}\n", .{ a, b });
    const r = blk: {
        const denom = a.v[1] * b.v[0] - b.v[1] * a.v[0];
        if (@abs(denom) < eps) {
            print("  reject a denom: {}\n", .{denom});
            return false;
        }
        const numer = a.v[0] * (b.p[1] - a.p[1]) - a.v[1] * (b.p[0] - a.p[0]);
        break :blk numer / denom;
    };
    const t = blk: {
        const denom = a.v[0];
        if (@abs(denom) < eps) {
            print("  reject a denom: {}\n", .{denom});
            return false;
        }
        const numer = b.p[0] + b.v[0] * r - a.p[0];
        break :blk numer / denom;
    };
    const in: [2]f64 = .{
        b.p[0] + b.v[0] * r,
        b.p[1] + b.v[1] * r,
    };
    if (r <= 0) {
        print("  reject r in past: {} < 0\n", .{r});
        return false;
    }
    if (t <= 0) {
        print("  reject t in past: {} < 0\n", .{t});
        return false;
    }

    if (in[0] < test_range[0] or in[0] > test_range[1] or
        in[1] < test_range[0] or in[1] > test_range[1])
    {
        print("  reject intersection {any}\n", .{in});
        return false;
    }

    print("  accept intersection {any}\n", .{in});
    return true;
}

fn wikipedia_hailstones_intersect(a: H, b: H, test_range: [2]f64) bool {
    // wikipedia line-intersection - this works too
    print("wikipedia test:\n{any}\n{any}\n", .{ a, b });
    const x = [_]f64{
        0,
        a.p[0],
        a.p[0] + a.v[0],
        b.p[0],
        b.p[0] + b.v[0],
    };
    const y = [_]f64{
        0,
        a.p[1],
        a.p[1] + a.v[1],
        b.p[1],
        b.p[1] + b.v[1],
    };
    const denom = (x[1] - x[2]) * (y[3] - y[4]) - (y[1] - y[2]) * (x[3] - x[4]);
    if (denom == 0) {
        print("  reject denom: {}\n", .{denom});
        return false;
    }
    const t = ((x[1] - x[3]) * (y[3] - y[4]) - (y[1] - y[3]) * (x[3] - x[4])) / denom;
    const r = ((x[1] - x[3]) * (y[1] - y[2]) - (y[1] - y[3]) * (x[1] - x[2])) / denom;
    if (t <= 0) {
        print("  reject t: {} < 0\n", .{t});
        return false;
    }
    if (r <= 0) {
        print("  reject r: {} < 0\n", .{r});
        return false;
    }
    const px = x[1] + t * (x[2] - x[1]);
    const py = y[1] + t * (y[2] - y[1]);

    if (px < test_range[0] or px > test_range[1] or
        py < test_range[0] or py > test_range[1])
    {
        print("  reject intersection ({}, {})\n", .{ px, py });
        return false;
    }

    if (false) { // this is not necessary! checking t > 0 and r > 0 achieves the same
        if ((px - a.p[0]) * a.v[0] + (py - a.p[1]) * a.v[1] < 0) {
            print("  reject a in past\n", .{});
            return false;
        }
        if ((px - b.p[0]) * b.v[0] + (py - b.p[1]) * b.v[1] < 0) {
            print("  reject b in past\n", .{});
            return false;
        }
    }

    print("  accept intersection ({}, {})\n", .{ px, py });
    return true;
}

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var line_it = u.strTokLine(input);
    var stones = AL(H).init(heap);

    while (line_it.next()) |line| {
        var it = u.strTokAny(line, " ,@");
        var h = std.mem.zeroInit(H, .{});
        for (0..3) |i| {
            h.p[i] = try std.fmt.parseFloat(f64, it.next().?);
        }
        for (0..3) |i| {
            h.v[i] = try std.fmt.parseFloat(f64, it.next().?);
        }
        try stones.append(h);
    }
    const test_range = if (stones.items.len < 100) test_test_range else real_test_range;
    if (part2) {} else {
        for (0..stones.items.len) |i| {
            for ((i + 1)..stones.items.len) |j| {
                const a = stones.items[i];
                const b = stones.items[j];

                const w = wikipedia_hailstones_intersect(a, b, test_range);
                const m = hailstones_intersect(a, b, test_range);
                assert(w == m);
                if (m) {
                    total += 1;
                }
            }
        }
    }

    return total;
}

pub fn main() !void {
    const input = try u.getInput();
    stdprint("{}\n", .{try solve(input, false)});
    //stdprint("{}\n", .{try solve(input, true)});
}
