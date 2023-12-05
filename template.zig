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

    print("{s}\n", .{input});
}
