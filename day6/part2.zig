const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSequence = std.mem.tokenizeSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    const f = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    defer f.close();
    return try f.readToEndAlloc(m, std.math.maxInt(usize));
}

pub fn main() !void {
    const input = try getInput();
    var time_str = std.ArrayList(u8).init(m);
    var dist_str = std.ArrayList(u8).init(m);
    var line_it = tokenizeAny(u8, input, "\n");
    var time_it = tokenizeAny(u8, line_it.next().?, ": ");
    var dist_it = tokenizeAny(u8, line_it.next().?, ": ");
    _ = time_it.next().?;
    _ = dist_it.next().?;
    while (time_it.next()) |t| {
        try time_str.appendSlice(t);
        try dist_str.appendSlice(dist_it.next().?);
    }
    const race = .{ try parseInt(usize, time_str.items, 10), try parseInt(usize, dist_str.items, 10) };
    print("{any}\n", .{race});

    var total: usize = 1;

    var num_ways: usize = 0;
    var held_ms: usize = 0;
    const half = @divTrunc(race[0], 2);
    print("half: {}\n", .{half});
    while (held_ms <= half) : (held_ms += 1) {
        const speed = held_ms;
        const time_left = race[0] - held_ms;
        if (speed * time_left > race[1]) {
            num_ways += 1;
            if (held_ms < 50) {
                print("  {}\n", .{held_ms});
            }
        }
    }
    num_ways *= 2;
    if (race[0] & 1 == 0) {
        num_ways -= 1;
    }
    //print("{}\n", .{num_ways});
    total *= num_ways;

    print("{}\n", .{total});
}
