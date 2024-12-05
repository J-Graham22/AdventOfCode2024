const std = @import("std");

const Position: type = struct { i32, i32 };

const XPositions = struct {
    positions: std.ArrayList([5]Position),

    pub fn init(allocator: std.mem.Allocator) XPositions {
        return .{
            .positions = std.ArrayList([5]Position).init(allocator),
        };
    }

    pub fn deinit(self: *XPositions) void {
        self.positions.deinit();
    }

    // pub fn checkForExistingX(self: *XPositions, positions: [5]Position) bool {
    //     for (self.*.positions.items) |item| {
    //         //if (self.*.positions.items.len < 5) std.debug.print("number of Xes {d}\n", .{self.*.positions.items.len});
    //         //if the all items in positions can be found in item, then the X has been found already
    //         //if not, then it does not exist
    //         var foundPositions: bool = true;

    //         for (positions) |pos| {
    //             //check for the pos existing within the list of points
    //             var pointFound: bool = false;
    //             for (item) |point| {
    //                 if (pos[0] == point[0] and pos[1] == point[1]) {
    //                     //if (pos[0] < 2) std.debug.print("pos {d},{d} point {d},{d}\n", .{ pos[0], pos[1], point[0], point[1] });
    //                     pointFound = true;
    //                     break;
    //                 }
    //             }
    //             if (!pointFound) {
    //                 //if (pos[0] < 3) std.debug.print("pos {d},{d} not found, setting foundPositions to false\n", .{ pos[0], pos[1] });
    //                 foundPositions = false;
    //             }
    //         }

    //         if (self.*.positions.items.len < 5) std.debug.print("foundPositions {}\n", .{foundPositions});

    //         if (foundPositions) return true;
    //     }
    //     return false;
    // }

    pub fn checkForExistingX(self: *XPositions, positions: [5]Position) bool {
        for (self.positions.items) |existing| {
            var matchCount: u8 = 0;

            // Count how many positions match between existing and new X
            for (existing) |existingPos| {
                for (positions) |newPos| {
                    if (existingPos[0] == newPos[0] and existingPos[1] == newPos[1]) {
                        matchCount += 1;
                        break;
                    }
                }
            }

            // If all 5 positions match, we found a duplicate X
            if (matchCount == 5) return true;
        }
        return false;
    }

    pub fn toString(self: *XPositions) ![]u8 {
        const allocator = std.mem.Allocator;
        var result = std.ArrayList(u8).init(allocator);
        errdefer result.deinit();

        try result.appendSlice("Positions: ");

        for (self.positions.items, 0..) |pos, i| {
            try result.writer().print("X{d}: ", .{i + 1});
            for (pos) |p| {
                try result.writer().print("({d},{d}) ", .{ p[0], p[1] });
            }
            try result.appendSlice("\n");
        }

        return result.toOwnedSlice();
    }
};

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

    var positions: XPositions = XPositions.init(allocator);

    //var xmasCount: i32 = 0;
    var x_masCount: i32 = 0;
    for (0..crossWord.items.len) |i| {
        for (0..crossWord.items[0].len) |j| {
            //xmasCount += xmasCheck(crossWord, @intCast(i), @intCast(j));
            x_masCount += X_masCheck(crossWord, @intCast(i), @intCast(j), &positions);
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

pub fn X_masCheck(crossWord: std.ArrayList([]u8), i: i32, j: i32, positions: *XPositions) i32 {
    var xmasCount: i32 = 0;

    //north west
    if (x_masCheckDirection(crossWord, i, j, -1, -1, positions)) xmasCount += 1;
    //north east
    if (x_masCheckDirection(crossWord, i, j, 1, -1, positions)) xmasCount += 1;
    //south west
    if (x_masCheckDirection(crossWord, i, j, -1, 1, positions)) xmasCount += 1;
    //south east
    if (x_masCheckDirection(crossWord, i, j, 1, 1, positions)) xmasCount += 1;

    if (xmasCount > 0 and i < 10) std.debug.print("position {d},{d} xmas count {d}\n", .{ i, j, xmasCount });

    return xmasCount;
}

pub fn x_masCheckDirection(crossWord: std.ArrayList([]u8), col: i32, row: i32, iIncrementValue: i32, jIncrementValue: i32, positions: *XPositions) bool {
    //first check that the MAS exists in the intended direction
    if (!checkForMAS(crossWord, col, row, iIncrementValue, jIncrementValue)) return false;

    //then need to check the 2 remaining corners to see if they make a MAS
    const corner1 = crossWord.items[@intCast(col + (iIncrementValue * 2))][@intCast(row)];
    const corner2 = crossWord.items[@intCast(col)][@intCast(row + (jIncrementValue * 2))];
    if ((corner1 == 'M' and corner2 == 'S') or corner1 == 'S' and corner2 == 'M') {
        const points: [5]Position = .{
            .{ col, row },
            .{ col + iIncrementValue, row + jIncrementValue },
            .{ col + (iIncrementValue * 2), row + (jIncrementValue * 2) },
            .{ col + (iIncrementValue * 2), row },
            .{ col, row + (jIncrementValue * 2) },
        };

        if (!positions.checkForExistingX(points)) {
            positions.positions.append(points) catch {
                return false;
            };
        } else {
            //std.debug.print("X MAS found, but already found before\n", .{});
        }
    }

    // if (checkForMAS(crossWord, col + (iIncrementValue * 2), row, iIncrementValue, jIncrementValue) or
    //     checkForMAS(crossWord, col, row + (jIncrementValue * 2), iIncrementValue, jIncrementValue)) return true;

    // if (col < 50) std.debug.print("found first MAS, but didn't complete the X: pos {d},{d}\n", .{ col, row });

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
