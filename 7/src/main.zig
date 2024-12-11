const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    print("All your {s} are belong to us.\n", .{"codebase"});

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    const allocator = std.heap.page_allocator;

    var totalValidTestValues: u64 = 0;

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var targetAndNums = std.mem.splitSequence(u8, line, ":");

        var target: u64 = 0;
        var numsList = std.ArrayList(u64).init(allocator);
        defer numsList.deinit();

        while (targetAndNums.next()) |i| {
            if (target == 0) {
                target = try std.fmt.parseInt(u64, i, 10);
                continue;
            }

            var numsIter = std.mem.splitSequence(u8, i, " ");
            while (numsIter.next()) |num| {
                const parseIntErrors = error{ Overflow, InvalidCharacter };

                const numOut: parseIntErrors!u64 = std.fmt.parseInt(u64, num, 10);

                if (numOut == parseIntErrors.Overflow or numOut == parseIntErrors.InvalidCharacter) {
                    continue;
                } else {
                    const val: u64 = try numOut;
                    try numsList.append(val);
                }
            }
        }

        if (try calculateNumsToTarget(target, numsList.items[0], numsList.items[1..], "+") or
            try calculateNumsToTarget(target, numsList.items[0], numsList.items[1..], "*") or
            try calculateNumsToTarget(target, numsList.items[0], numsList.items[1..], "|"))
        {
            print("target {d} is valid\n", .{target});
            totalValidTestValues += target;
        }
    }

    print("total valid test values {d}\n", .{totalValidTestValues});
}

pub fn calculateNumsToTarget(target: u64, currentAmount: u64, nums: []u64, operator: *const [1:0]u8) !bool {
    if (nums.len == 0) {
        //base case -> no more numbers to calculate
        return target == currentAmount;
    }

    var currAmountMut = currentAmount;

    if (std.mem.eql(u8, operator, "+")) {
        currAmountMut += nums[0];
    }
    if (std.mem.eql(u8, operator, "*")) {
        currAmountMut *= nums[0];
    }
    if (std.mem.eql(u8, operator, "|")) {
        const allocator = std.heap.page_allocator;
        const str = try std.fmt.allocPrint(allocator, "{d}{d}", .{ currAmountMut, nums[0] });
        const concatenatedNum = try std.fmt.parseInt(u64, str, 10);
        currAmountMut = concatenatedNum;
    }

    if (nums.len > 1) {
        return try calculateNumsToTarget(target, currAmountMut, nums[1..], "+") or
            try calculateNumsToTarget(target, currAmountMut, nums[1..], "*") or
            try calculateNumsToTarget(target, currAmountMut, nums[1..], "|");
    } else {
        return try calculateNumsToTarget(target, currAmountMut, &.{}, "+") or
            try calculateNumsToTarget(target, currAmountMut, &.{}, "*") or
            try calculateNumsToTarget(target, currAmountMut, &.{}, "|");
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
