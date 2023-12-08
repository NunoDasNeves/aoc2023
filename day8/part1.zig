const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;
const parseUnsigned = std.fmt.parseUnsigned;

const trim = std.mem.trim;
const ascii = std.ascii;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn strTokAny(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeAny = std.mem.tokenizeAny;
    return tokenizeAny(u8, str, delimiters);
}

fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    const tokenizeSequence = std.mem.tokenizeSequence;
    return tokenizeSequence(u8, str, delimiters);
}

fn strTokLine(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, '\n');
}

fn strTokSpace(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    const tokenizeScalar = std.mem.tokenizeScalar;
    return tokenizeScalar(u8, str, ' ');
}

fn strTrim(str: []const u8, values: []const u8) []const u8 {
    return trim(u8, str, values);
}

fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}

const Node = struct {
    K: []const u8,
    L: []const u8,
    R: []const u8,
};

const HashCtx = struct {
    pub fn hash(self: HashCtx, key: []const u8) u64 {
        _ = self;
        return std.hash.CityHash64.hash(key);
    }
    pub fn eql(self: HashCtx, a: []const u8, b: []const u8) bool {
        _ = self;
        return std.mem.eql(u8, a, b);
    }
};

pub fn main() !void {
    const input = try getInput();
    var map = std.HashMap([]const u8, Node, HashCtx, 80).init(m);
    var line_it = strTokLine(input);
    const directions = line_it.next().?;
    //const start: u32 = std.mem.readInt(u32, "AAA", .little);
    //const end: u32 = std.mem.readInt(u32, "ZZZ", .little);
    const start = "AAA";
    const end = "ZZZ";
    print("{s}\n", .{directions});

    while (line_it.next()) |line| {
        var it = strTokAny(line, "= (,)");
        const key = it.next().?;
        const node = Node{
            .K = key,
            .L = it.next().?,
            .R = it.next().?,
        };
        print("{s} {any}\n", .{ key, node });
        try map.put(key, node);
    }
    var total: usize = 0;
    var curr_node: Node = map.get(start).?;
    loop: while (true) {
        for (directions) |d| {
            const next: []const u8 = switch (d) {
                'L' => curr_node.L,
                'R' => curr_node.R,
                else => unreachable,
            };
            curr_node = map.get(next).?;
            total += 1;
            if (std.mem.eql(u8, curr_node.K, end)) {
                break :loop;
            }
        }
    }
    print("{}\n", .{total});
}
