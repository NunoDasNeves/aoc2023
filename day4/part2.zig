const std = @import("std");
const print = std.debug.print;
const tokenizeAny = std.mem.tokenizeAny;
const splitSequence = std.mem.splitSequence;
const parseInt = std.fmt.parseInt;
const trim = std.mem.trim;
const ArrayList = std.ArrayList;

const test_input =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;
const real_input = @embedFile("input");

fn is_digit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const m = gpa.allocator();
    var card_counts = ArrayList(usize).init(m);

    var total_cards: usize = 0;
    //const input = test_input;
    const input = real_input;

    var line_it = tokenizeAny(u8, input, "\n");
    while (line_it.next()) |_| {
        try card_counts.append(1);
    }

    var cards_it = tokenizeAny(u8, input, "\n");
    while (cards_it.next()) |line| {
        var num_winning: usize = 0;
        var card_it = tokenizeAny(u8, line, ":|");
        var card_num_it = tokenizeAny(u8, card_it.next().?, " ");
        _ = card_num_it.next();
        const card_num = try parseInt(usize, card_num_it.next().?, 10);

        const winning_str = trim(u8, card_it.next().?, " ");
        const nums_str = trim(u8, card_it.next().?, " ");
        var winning_set: [100]bool = undefined;
        @memset(&winning_set, false);
        var winning_it = tokenizeAny(u8, winning_str, " ");
        var nums_it = tokenizeAny(u8, nums_str, " ");

        while (winning_it.next()) |num_str| {
            const num = try parseInt(u8, num_str, 10);
            if (num > 99) {
                unreachable;
            }
            winning_set[num] = true;
        }
        while (nums_it.next()) |num_str| {
            const num = try parseInt(u8, num_str, 10);
            if (num > 99) {
                unreachable;
            }
            if (winning_set[num]) {
                num_winning += 1;
            }
        }
        for (card_num..card_num + num_winning) |card_index| {
            card_counts.items[card_index] += card_counts.items[card_num - 1];
        }
    }

    for (card_counts.items) |count| {
        total_cards += count;
    }

    //print("{s}\n", .{input});
    print("{}\n", .{total_cards});
}
