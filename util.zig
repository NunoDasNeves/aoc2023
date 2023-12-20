const std = @import("std");

const parseInt = std.fmt.parseInt;

const trim = std.mem.trim;
const tokenizeScalar = std.mem.tokenizeScalar;
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSequence = std.mem.tokenizeSequence;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

pub fn lcm(comptime T: type, nums: []T) T {
    var ret: T = 1;
    for (nums) |num| {
        ret *= @divExact(num, std.math.gcd(ret, num));
    }
    return ret;
}

pub fn strEql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn strTokAny(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .any) {
    return tokenizeAny(u8, str, delimiters);
}

pub fn strTokSeq(str: []const u8, delimiters: []const u8) std.mem.TokenIterator(u8, .sequence) {
    return tokenizeSequence(u8, str, delimiters);
}

pub fn strTokLine(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    return tokenizeScalar(u8, str, '\n');
}

pub fn strTokSpace(str: []const u8) std.mem.TokenIterator(u8, .scalar) {
    return tokenizeScalar(u8, str, ' ');
}

pub fn strTrim(str: []const u8, values: []const u8) []const u8 {
    return trim(u8, str, values);
}

pub fn parseIntListAny(comptime T: type, str: []const u8, delimiters: []const u8) ![]T {
    var arr = std.ArrayList(T).init(m);
    var it = tokenizeAny(u8, str, delimiters);
    while (it.next()) |s| {
        try arr.append(try parseInt(T, s, 10));
    }
    return arr.toOwnedSlice();
}

pub fn getInput() ![]const u8 {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    return std.fs.cwd().readFileAlloc(m, args[1], std.math.maxInt(usize));
}

pub fn StaticBuf(comptime Array: type) type {
    const info = @typeInfo(Array);
    const Child = info.Array.child;
    return struct {
        storage: Array = std.mem.zeroes(Array),
        buf: []Child = &.{},

        pub fn append(self: *@This(), item: Child) bool {
            if (self.buf.len >= self.storage.len) {
                return false;
            }
            self.storage[self.buf.len] = item;
            self.buf = self.storage[0 .. self.buf.len + 1];
            return true;
        }
        pub fn orderedRemove(self: *@This(), i: usize) Child {
            std.debug.assert(i < self.buf.len);
            var j = i;
            const ret = self.buf[i];
            while (j < self.buf.len - 1) : (j += 1) {
                self.buf[j] = self.buf[j + 1];
            }
            self.buf = self.storage[0 .. self.buf.len - 1];
            return ret;
        }
        pub fn isFull(self: *@This()) bool {
            return self.buf.len == self.storage.len;
        }
    };
}
