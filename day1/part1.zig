const std = @import("std");
const print = std.debug.print;

const test_input =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
    \\
;
const real_input = @embedFile("input");

pub fn main() void {
    var total: i32 = 0;
    var first: i32 = 0;
    var last: i32 = 0;
    var found_first: bool = false;
    //const input = test_input;
    const input = real_input;

    for (input) |char| {
        if (char == '\n') {
            //print("{}, {}\n", .{first, last});
            total += first * 10;
            total += last;
            //print("{}\n", .{total});
            found_first = false;
            continue;
        }
        if (char < '0' or char > '9') {
            continue;
        }
        const val: i32 = char - '0';
        if (!found_first) {
            first = val;
            found_first = true;
        }
        last = val;
    }
    //print("{s}\n", .{input});
    print("{}\n", .{total});
}
