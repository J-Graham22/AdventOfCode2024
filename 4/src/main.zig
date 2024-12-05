const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const allocator = std.heap.page_allocator;
    var crossWord = std.ArrayList([]u8).init(allocator);
    defer crossWord.deinit();

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const copy = try allocator.dupe(u8, line);
        try crossWord.append(copy);
    }

    //var xmasCount: i32 = 0;
    var x_masCount: i32 = 0;
    for (0..crossWord.items.len) |i| {
        for (0..crossWord.items[0].len) |j| {
            //xmasCount += xmasCheck(crossWord, @intCast(i), @intCast(j));
            //x_masCount += X_masCheck(crossWord, @intCast(i), @intCast(j));
            if (X_masCheck(crossWord, @intCast(i), @intCast(j))) x_masCount += 1;
        }
        //std.debug.print("\n", .{});
    }
    //std.debug.print("xmasCount {d}\n", .{xmasCount});
    std.debug.print("x_mas count {d}\n", .{x_masCount});

    //free memory from array list
    for (crossWord.items) |item| {
        allocator.free(item);
    }
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

pub fn xmasCheck(crossWord: std.ArrayList([]u8), i: i32, j: i32) i32 {
    var xmasCount: i32 = 0;
    //left
    if (xmasCheckDirection(crossWord, i, j, -1, 0)) xmasCount += 1;
    //right
    if (xmasCheckDirection(crossWord, i, j, 1, 0)) xmasCount += 1;
    //up
    if (xmasCheckDirection(crossWord, i, j, 0, -1)) xmasCount += 1;
    //down
    if (xmasCheckDirection(crossWord, i, j, 0, 1)) xmasCount += 1;
    //north west
    if (xmasCheckDirection(crossWord, i, j, -1, -1)) xmasCount += 1;
    //north east
    if (xmasCheckDirection(crossWord, i, j, 1, -1)) xmasCount += 1;
    //south west
    if (xmasCheckDirection(crossWord, i, j, -1, 1)) xmasCount += 1;
    //south east
    if (xmasCheckDirection(crossWord, i, j, 1, 1)) xmasCount += 1;

    //std.debug.print("position {d},{d} xmas count {d}\n", .{ i, j, xmasCount });

    return xmasCount;
}

pub fn xmasCheckDirection(crossWord: std.ArrayList([]u8), col: i32, row: i32, iIncrementValue: i32, jIncrementValue: i32) bool {
    var i = col;
    var j = row;

    const xmas = "XMAS";

    for (xmas) |char| {
        if (i < 0 or i >= crossWord.items.len or j < 0 or j >= crossWord.items[0].len) return false;

        if (crossWord.items[@intCast(i)][@intCast(j)] != char) return false;

        i += iIncrementValue;
        j += jIncrementValue;
    }

    return true;
}

pub fn X_masCheck(crossWord: std.ArrayList([]u8), i: i32, j: i32) bool {
    if (crossWord.items[@intCast(i)][@intCast(j)] != 'A') return false;

    //check if the corners are within the bounds of the cross word
    if (i + 1 >= crossWord.items.len or
        i - 1 < 0 or
        j + 1 >= crossWord.items[0].len or
        j - 1 < 0) return false;

    //check all 4 kinds of Xes

    //M . M
    //. A .
    //S . S
    if (crossWord.items[@intCast(i - 1)][@intCast(j - 1)] == 'M' and //top left
        crossWord.items[@intCast(i - 1)][@intCast(j + 1)] == 'M' and //top right
        crossWord.items[@intCast(i + 1)][@intCast(j - 1)] == 'S' and //bottom left
        crossWord.items[@intCast(i + 1)][@intCast(j + 1)] == 'S' //bottom right
    ) return true;

    //M . S
    //. A .
    //M . S
    if (crossWord.items[@intCast(i - 1)][@intCast(j - 1)] == 'M' and //top left
        crossWord.items[@intCast(i - 1)][@intCast(j + 1)] == 'S' and //top right
        crossWord.items[@intCast(i + 1)][@intCast(j - 1)] == 'M' and //bottom left
        crossWord.items[@intCast(i + 1)][@intCast(j + 1)] == 'S' //bottom right
    ) return true;

    //S . S
    //. A .
    //M . M
    if (crossWord.items[@intCast(i - 1)][@intCast(j - 1)] == 'S' and //top left
        crossWord.items[@intCast(i - 1)][@intCast(j + 1)] == 'S' and //top right
        crossWord.items[@intCast(i + 1)][@intCast(j - 1)] == 'M' and //bottom left
        crossWord.items[@intCast(i + 1)][@intCast(j + 1)] == 'M' //bottom right
    ) return true;

    //S . M
    //. A .
    //S . M
    if (crossWord.items[@intCast(i - 1)][@intCast(j - 1)] == 'S' and //top left
        crossWord.items[@intCast(i - 1)][@intCast(j + 1)] == 'M' and //top right
        crossWord.items[@intCast(i + 1)][@intCast(j - 1)] == 'S' and //bottom left
        crossWord.items[@intCast(i + 1)][@intCast(j + 1)] == 'M' //bottom right
    ) return true;

    return false;
}

pub fn checkForMAS(crossWord: std.ArrayList([]u8), col: i32, row: i32, iIncrementValue: i32, jIncrementValue: i32) bool {
    var i = col;
    var j = row;

    const xmas = "MAS";

    for (xmas) |char| {
        if (i < 0 or i >= crossWord.items.len or j < 0 or j >= crossWord.items[0].len) return false;

        if (crossWord.items[@intCast(i)][@intCast(j)] != char) return false;

        i += iIncrementValue;
        j += jIncrementValue;
    }

    return true;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
