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

fn get_val(ch: u8) u8 {
    return switch (ch) {
        '2'...'9' => ch - '2',
        'T' => 10,
        'J' => 11,
        'Q' => 12,
        'K' => 13,
        'A' => 14,
        else => unreachable,
    };
}

const Hand = struct {
    vals: [5]u8,
    bid: usize,
    hand_type: u8,
    fn init(str: []const u8, bid: usize) Hand {
        var set: [15]u8 = undefined;
        @memset(&set, 0);
        var ret: Hand = std.mem.zeroInit(Hand, .{});
        for (str, 0..) |ch, i| {
            const val = get_val(ch);
            ret.vals[i] = val;
            set[val] += 1;
        }
        var pairs: u8 = 0;
        var dup: u8 = 0;
        for (set) |num| {
            if (num == 2) {
                pairs += 1;
            } else if (num >= 3) {
                dup = num;
            }
        }
        //print("pairs: {}, dup: {}, {any}\n", .{ pairs, dup, set });
        ret.hand_type = switch (dup) {
            5 => 6,
            4 => 5,
            3 => if (pairs > 0) 4 else 3,
            else => if (pairs >= 1) pairs else 0,
        };
        ret.bid = bid;
        return ret;
    }
    fn lessThan(ctx: @TypeOf(.{}), lhs: Hand, rhs: Hand) bool {
        _ = ctx;
        if (lhs.hand_type != rhs.hand_type) {
            return lhs.hand_type < rhs.hand_type;
        }
        for (lhs.vals, rhs.vals) |lh, rh| {
            if (lh != rh) {
                return lh < rh;
            }
        }
        return false;
    }
};

pub fn main() !void {
    const input = try getInput();
    var hands_arr = std.ArrayList(Hand).init(m);
    var line_it = strTokLine(input);
    while (line_it.next()) |line| {
        var it = strTokSpace(line);
        const hand_str = it.next().?;
        const bid = try parseInt(usize, it.next().?, 10);
        try hands_arr.append(Hand.init(hand_str, bid));
    }
    std.sort.pdq(Hand, hands_arr.items, .{}, Hand.lessThan);
    var total: usize = 0;
    for (hands_arr.items, 0..) |hand, i| {
        total += hand.bid * (i + 1);
    }
    //print("{any}\n", .{hands_arr.items});
    print("{}\n", .{total});
}
