const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const util = @import("util.zig");

const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn HASH(buf: []const u8) u8 {
    var x: u64 = 0;
    for (buf) |ch| {
        x += ch;
        x *= 17;
        x %= 256;
    }
    return @intCast(x);
}

const Entry = struct {
    k: []const u8,
    v: usize,
};

fn solve(input: []const u8, part2: bool) !usize {
    var total: usize = 0;
    var boxes: [256]std.DoublyLinkedList(Entry) = undefined;
    for (&boxes) |*box| {
        box.* = std.DoublyLinkedList(Entry){};
        defer {
            while (box.pop()) |node| {
                m.destroy(node);
            }
        }
    }
    var step_it = util.strTokAny(input, "\n,");
    if (!part2) {
        while (step_it.next()) |step| {
            total += HASH(step);
        }
        return total;
    }
    // part2
    while (step_it.next()) |step| {
        var put_it = util.strTokAny(step, "=-");
        const label = put_it.next().?;
        const idx = HASH(label);
        const box = &boxes[idx];
        if (put_it.next()) |f| {
            const focal_length = try parseInt(usize, f, 10);
            var curr = box.first;
            var found = false;
            while (curr) |node| {
                if (std.mem.eql(u8, node.data.k, label)) {
                    node.data.v = focal_length;
                    found = true;
                    break;
                }
                curr = node.next;
            }
            if (!found) {
                var new_node = try m.create(@TypeOf(boxes[0].first.?.*));
                new_node.data.k = label;
                new_node.data.v = focal_length;
                box.append(new_node);
            }
        } else {
            var curr = box.first;
            while (curr) |node| {
                if (std.mem.eql(u8, node.data.k, label)) {
                    box.remove(node);
                    break;
                }
                curr = node.next;
            }
        }
        for (boxes, 0..) |b, i| {
            _ = i;

            var curr = b.first;
            var slot_num: usize = 1;
            if (curr == null) {
                continue;
            }
            //print("Box {}: ", .{i});
            while (curr) |node| {
                //print("[{s} {}] ", .{ node.data.k, node.data.v });
                slot_num += 1;
                curr = node.next;
            }
            //print("\n", .{});
        }
        //print("\n", .{});
    }
    for (boxes, 0..) |box, i| {
        var curr = box.first;
        var slot_num: usize = 1;
        while (curr) |node| {
            total += (i + 1) * slot_num * node.data.v;
            slot_num += 1;
            curr = node.next;
        }
    }
    return total;
}

pub fn main() !void {
    const input = try util.getInput();

    print("{}\n", .{try solve(input, false)});
    print("{}\n", .{try solve(input, true)});
}
