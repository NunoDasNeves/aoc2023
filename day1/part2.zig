const std = @import("std");
const print = std.debug.print;

const test_input =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
    \\
;
const real_input = @embedFile("input");
const digits = [_][]const u8 {
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

pub fn main() void {
    var total: usize = 0;
    var first: usize = 0;
    var last: usize = 0;
    var found_first: bool = false;
    //const input = test_input;
    const input = real_input;

    outer: for (input, 0..input.len) |char, i| {
        if (char == '\n') {
            //print("{}, {}\n", .{first, last});
            total += first * 10;
            total += last;
            //print("{}\n", .{total});
            found_first = false;
            continue;
        }
        var val: usize = 0;
        if (char >= 'a' and char <= 'z') {
            val = digits_loop: for (digits, 0..digits.len) |digit, digit_index| {
                var j: usize = 0;
                while (j < digit.len and input[i + j] == digit[j]) : (j += 1) {}
                if (j == digit.len) {
                    val = break :digits_loop digit_index + 1;
                }
            } else {
                continue :outer;
            };
        } else if (char >= '0' and char <= '9') {
            val = char - '0';
        } else {
            continue;
        }

        if (!found_first) {
            first = val;
            found_first = true;
        }
        last = val;
    }
    //print("{s}\n", .{input});
    print("{}\n", .{total});
}
