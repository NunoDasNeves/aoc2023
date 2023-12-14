const std = @import("std");
const print = std.debug.print;
const parseUnsigned = std.fmt.parseUnsigned;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const m = gpa.allocator();

fn print_usage(args: [][]u8) void {
    const binname = std.fs.path.basename(args[0]);
    print("usage: {s} DAY_NUM [NEW_COOKIE_STR]\n", .{binname});
}

pub fn main() !void {
    const args = try std.process.argsAlloc(m);
    defer std.process.argsFree(m, args);
    if (args.len < 2) {
        print_usage(args);
        return;
    }
    const daynum = try parseUnsigned(usize, args[1], 10);
    if (args.len > 2) {
        const cookie = args[2];
        try std.fs.cwd().writeFile2(.{ .data = cookie, .sub_path = "cookie", .flags = .{} });
    }
    const cookie_str = try std.fs.cwd().readFileAlloc(m, "cookie", 1024);
    const dirname = try std.fmt.allocPrint(m, "day{}", .{daynum});
    try std.fs.cwd().makePath(dirname);
    const daydir = try std.fs.cwd().openDir(dirname, .{});

    const solfile = "sol.zig";
    if (daydir.statFile(solfile)) |_| {} else |_| {
        try std.fs.cwd().copyFile("template.zig", daydir, solfile, .{});
        print("copy {s} to {s}/{s}\n", .{ "template.zig", dirname, solfile });
    }

    const utilfile = "util.zig";
    if (daydir.statFile(utilfile)) |_| {} else |_| {
        try std.fs.cwd().copyFile("util.zig", daydir, utilfile, .{});
        print("copy {s} to {s}/{s}\n", .{ "util.zig", dirname, utilfile });
    }

    const input_url = try std.fmt.allocPrint(m, "https://adventofcode.com/2023/day/{}/input", .{daynum});
    var cl = std.http.Client{
        .allocator = m,
    };
    var headers = std.http.Headers.init(m);
    const session_str = try std.fmt.allocPrint(m, "session={s}", .{cookie_str});
    try headers.append("Cookie", session_str);
    const fetch_result = try cl.fetch(m, .{
        .method = .GET,
        .location = .{ .url = input_url },
        .headers = headers,
    });
    const input = fetch_result.body.?;
    print("get input\n", .{});
    try daydir.writeFile2(.{ .data = input, .sub_path = "input", .flags = .{} });
    print("create input\n", .{});

    for (0..3) |i| {
        const tin = try std.fmt.allocPrint(m, "test_input_{}", .{i});
        defer m.free(tin);
        if (daydir.statFile(tin)) |_| {} else |_| {
            try daydir.writeFile2(.{ .data = "", .sub_path = tin, .flags = .{} });
            print("create (empty) {s}\n", .{tin});
        }
    }
}
