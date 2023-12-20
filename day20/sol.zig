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

const Mod = struct {
    name: []const u8,
    t: enum {
        bcast,
        ff,
        conj,
    },
    to: [][]const u8 = undefined,
    from: std.StringArrayHashMap(u8) = undefined,
    val: u8 = 0,
};

fn solve(input: []const u8, part2: bool) !u64 {
    var line_it = u.strTokLine(input);
    var mods = std.StringArrayHashMap(Mod).init(heap);
    // output mod name, and the conjunction mod that feeds it
    const output = "rx";
    var out_conj: []const u8 = undefined;

    while (line_it.next()) |line| {
        var __it = u.strTokAny(line, " ->,");
        const first = __it.next().?;
        var mod: Mod = switch (first[0]) {
            '%' => .{ .name = first[1..], .t = .ff },
            '&' => .{ .name = first[1..], .t = .conj, .from = std.StringArrayHashMap(u8).init(heap) },
            'b' => .{ .name = first, .t = .bcast },
            else => unreachable,
        };
        var to_arr = AL([]const u8).init(heap);
        while (__it.next()) |to| {
            try to_arr.append(to);
        }
        mod.to = try to_arr.toOwnedSlice();
        try mods.put(mod.name, mod);
    }
    for (mods.keys()) |key| {
        const mod = mods.getPtr(key).?;
        for (mod.to) |to| {
            if (mods.getPtr(to)) |next| {
                if (next.t == .conj) {
                    try next.from.put(key, 0);
                }
            }
            if (u.strEql(to, output)) {
                out_conj = mod.name;
            }
        }
    }
    // track button presses for modules that feed out_conj to output high
    // just leave space for 3 entries, more than is really needed
    var out_conj_counts = std.StringArrayHashMap(u.StaticBuf([3]u64)).init(heap);
    if (mods.get(out_conj)) |conj| {
        for (conj.from.keys()) |from| {
            try out_conj_counts.put(from, .{});
        }
    }

    var lo_count: u64 = 0;
    var hi_count: u64 = 0;
    var press_count: u64 = 0;
    presses: while (part2 or press_count < 1000) {
        press_count += 1;
        var queue = std.ArrayList(struct { from: []const u8, to: []const u8, val: u8 }).init(heap);
        try queue.append(.{ .from = "button", .to = "broadcaster", .val = 0 });
        while (queue.items.len > 0) {
            const signal = queue.orderedRemove(0);
            if (signal.val == 0) {
                lo_count += 1;
            } else {
                hi_count += 1;
            }
            if (part2 and signal.val == 1) {
                // record number of presses to send a 1 to dr, and where it came from
                if (u.strEql(signal.to, "dr")) {
                    var counts = out_conj_counts.getPtr(signal.from).?;
                    if (!counts.append(press_count)) {
                        break :presses;
                    }
                }
            }
            const _mod = mods.getPtr(signal.to);
            if (_mod == null) {
                continue;
            }
            var mod = _mod.?;
            var send: ?u8 = null;
            switch (mod.t) {
                .bcast => {
                    send = signal.val;
                },
                .conj => {
                    try mod.from.put(signal.from, signal.val);
                    var count: usize = 0;
                    for (mod.from.values()) |v| {
                        count += v;
                    }
                    if (count == mod.from.count()) {
                        send = 0;
                    } else {
                        send = 1;
                    }
                },
                .ff => {
                    if (signal.val == 0) {
                        mod.val ^= 1;
                        send = mod.val;
                    }
                },
            }
            if (send) |val| {
                for (mod.to) |to| {
                    try queue.append(.{ .from = mod.name, .to = to, .val = val });
                }
            }
        }
    }

    if (part2) {
        // find the periods (of hi signals) of the conj mods that feed output_conj
        var periods: u.StaticBuf([20]u64) = .{};
        for (out_conj_counts.values()) |val| {
            // assert the period has no remainder at the start
            assert(val.buf[0] == val.buf[1] - val.buf[0]);
            assert(periods.append(val.buf[0]));
        }
        return u.lcm(u64, periods.buf);
    }

    return lo_count * hi_count;
}

pub fn main() !void {
    const input = try u.getInput();
    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
