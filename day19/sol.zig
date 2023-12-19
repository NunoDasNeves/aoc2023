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

const Rule = struct {
    ch: usize,
    num: usize,
    cmp: *const fn (part_num: usize, rule_num: usize) bool,
    next: []const u8,
};

fn lt(part_num: usize, rule_num: usize) bool {
    return part_num < rule_num;
}
fn gt(part_num: usize, rule_num: usize) bool {
    return part_num > rule_num;
}
fn yes(part_num: usize, rule_num: usize) bool {
    _ = part_num;
    _ = rule_num;

    return true;
}

const Flow = []Rule;

const Part = [4]usize;

const PartRange = [4][2]usize;

fn chToIdx(ch: []const u8) ?usize {
    if (ch.len > 1) {
        return null;
    }
    return switch (ch[0]) {
        'x' => 0,
        'm' => 1,
        'a' => 2,
        's' => 3,
        else => null,
    };
}

var flows = std.StringHashMap(Flow).init(heap);

fn findAccepted(accepted_ranges: *AL(PartRange), _range: PartRange, flowname: []const u8) !void {
    const flow = flows.get(flowname).?;
    var range = _range;
    for (flow) |rule| {
        if (false) {
            var cmpch: u8 = 'Y';
            if (rule.cmp == lt) {
                cmpch = '<';
            } else if (rule.cmp == gt) {
                cmpch = '>';
            }
            print("  rule: {}{c}{}:{s}\n", .{ rule.ch, cmpch, rule.num, rule.next });
        }
        const is_accept = rule.next.len == 1 and rule.next[0] == 'A';
        const is_reject = rule.next.len == 1 and rule.next[0] == 'R';

        if (rule.cmp == yes) {
            if (is_accept) {
                //print("    accept range: {any}\n", .{range});
                try accepted_ranges.append(range);
                return;
            } else if (is_reject) {
                //print("    reject range: {any}\n", .{range});
                return;
            } else {
                try findAccepted(accepted_ranges, range, rule.next);
                return;
            }
        }
        var rng = &range[rule.ch];
        if (rng[0] > rng[1]) {
            unreachable;
        }
        if (rule.cmp == lt) {
            if (rng[0] >= rule.num) {
                rng[0] = rng[1] + 1;
                unreachable;
            } else {
                var more = true;
                var accept_range: [4][2]usize = range;
                accept_range[rule.ch] = .{ rng[0], @min(rng[1], rule.num - 1) };
                if (rng[1] >= rule.num) {
                    rng[0] = rule.num;
                } else {
                    more = false;
                }

                if (is_accept) {
                    //print("    accept range: {any}\n", .{accept_range});
                    try accepted_ranges.append(accept_range);
                } else if (is_reject) {
                    //print("    reject range: {any}\n", .{accept_range});
                } else {
                    try findAccepted(accepted_ranges, accept_range, rule.next);
                }
                if (!more) {
                    return;
                }
            }
        } else {
            if (rng[1] <= rule.num) {
                rng[0] = rng[1] + 1;
                unreachable;
            } else {
                var more = true;
                var accept_range: [4][2]usize = range;
                accept_range[rule.ch] = .{ @max(rng[0], rule.num + 1), rng[1] };
                //print("    aAAAA {any}\n", .{accept_range});
                if (rng[0] <= rule.num) {
                    rng[1] = rule.num;
                } else {
                    more = false;
                }

                if (is_accept) {
                    //print("    accept range: {any}\n", .{accept_range});
                    try accepted_ranges.append(accept_range);
                } else if (is_reject) {
                    //print("    reject range: {any}\n", .{range});
                } else {
                    try findAccepted(accepted_ranges, accept_range, rule.next);
                }
                if (!more) {
                    return;
                }
            }
        }
    }
}

fn solve(input: []const u8, part2: bool) !u64 {
    var total: u64 = 0;
    var __it = u.strTokSeq(input, "\n\n");
    var flows_it = u.strTokLine(__it.next().?);
    var parts_it = u.strTokLine(__it.next().?);

    while (flows_it.next()) |flow_str| {
        var _it = u.strTokAny(flow_str, "{},");
        const name = _it.next().?;
        var flow = AL(Rule).init(heap);
        while (_it.next()) |rule| {
            var it = u.strTokAny(rule, ":><");
            const first = it.next().?;
            const ch_idx = chToIdx(first);
            if (ch_idx) |ch| {
                const num = try parseUnsigned(usize, it.next().?, 10);
                const next = it.next().?;
                try flow.append(.{
                    .ch = ch,
                    .cmp = if (rule[1] == '<') lt else gt,
                    .next = next,
                    .num = num,
                });
            } else {
                try flow.append(.{
                    .ch = 0,
                    .cmp = yes,
                    .next = first,
                    .num = 0,
                });
            }
        }
        try flows.put(name, try flow.toOwnedSlice());
    }

    if (part2) {
        var accepted_ranges = AL(PartRange).init(heap);
        try findAccepted(&accepted_ranges, .{
            .{ 1, 4000 },
            .{ 1, 4000 },
            .{ 1, 4000 },
            .{ 1, 4000 },
        }, "in");
        for (accepted_ranges.items) |range| {
            //print("{any}\n", .{range});
            var count: u64 = 1;
            for (range) |nums| {
                count *= nums[1] - nums[0] + 1;
            }
            total += count;
        }
    } else {
        part_loop: while (parts_it.next()) |part_str| {
            var _it = u.strTokAny(part_str, "{},");
            var part: Part = undefined;
            while (_it.next()) |prop| {
                var it = u.strTokAny(prop, "=");
                const ch_idx = chToIdx(it.next().?).?;
                const num = try parseUnsigned(usize, it.next().?, 10);
                part[ch_idx] = num;
            }
            var currflow = flows.get("in");
            while (currflow) |flow| {
                for (flow) |rule| {
                    var match = false;
                    for (part, 0..) |num, ch_idx| {
                        _ = num;
                        if (ch_idx == rule.ch) {
                            if (rule.cmp(part[rule.ch], rule.num)) {
                                match = true;
                            }
                        }
                    }
                    if (match) {
                        if (rule.next.len == 1) {
                            switch (rule.next[0]) {
                                'R' => {
                                    currflow = null;
                                    continue :part_loop;
                                },
                                'A' => {
                                    currflow = null;
                                    for (part) |num| {
                                        total += num;
                                    }
                                    continue :part_loop;
                                },
                                else => {},
                            }
                        }
                        currflow = flows.get(rule.next);
                        break;
                    }
                }
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
