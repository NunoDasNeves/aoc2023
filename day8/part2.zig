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
    end_len: usize,
    cycle_len: usize,
    end: ?[]const u8,
    multi_end: bool,
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
    var start_nodes = std.ArrayList(Node).init(m);
    var curr_nodes = std.ArrayList(Node).init(m);
    var multiples = std.ArrayList(usize).init(m);
    print("{s}\n", .{directions});

    while (line_it.next()) |line| {
        var it = strTokAny(line, "= (,)");
        const key = it.next().?;
        const node = Node{
            .K = key,
            .L = it.next().?,
            .R = it.next().?,
            .cycle_len = 0,
            .end_len = 0,
            .end = null,
            .multi_end = false,
        };
        //print("{s} {any}\n", .{ key, node });
        try map.put(key, node);
        if (key[2] == 'A') {
            try start_nodes.append(node);
        }
    }
    for (start_nodes.items) |node| {
        try curr_nodes.append(node);
        try multiples.append(0);
    }

    for (start_nodes.items, 0..) |*start_node, i| {
        var steps: usize = 0;
        var node = start_node.*;
        loop: while (true) {
            for (directions) |d| {
                const next: []const u8 = switch (d) {
                    'L' => node.L,
                    'R' => node.R,
                    else => unreachable,
                };
                node = map.get(next).?;
                steps += 1;
                if (node.K[2] == 'Z') {
                    if (start_node.end) |end| {
                        defer print("k: {s}, end: {?s}, end_len: {}, cycle: {}, multi_end: {}\n", .{ start_node.K, start_node.end, start_node.end_len, start_node.cycle_len, start_node.multi_end });
                        if (std.mem.eql(u8, end, node.K)) {
                            start_node.cycle_len = steps;
                            multiples.items[i] = start_node.cycle_len;
                            break :loop;
                        } else {
                            start_node.multi_end = true;
                            break :loop;
                        }
                    } else {
                        start_node.end = node.K;
                        start_node.end_len = steps;
                        steps = 0;
                    }
                }
            }
        }
    }
    print("{any}\n", .{multiples.items});
    var lcm: usize = 1;
    for (multiples.items) |mul| {
        lcm = lcm * mul / std.math.gcd(lcm, mul);
    }
    print("{}\n", .{lcm});
}
