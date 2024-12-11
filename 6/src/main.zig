const std = @import("std");

const Direction = enum(u8) {
    Up = 0,
    Right = 1,
    Down = 2,
    Left = 3,
};

const Guard: type = struct {
    i: usize,
    j: usize,
    direction: Direction,

    pub fn init(i: usize, j: usize, direction: Direction) Guard {
        return Guard{
            .i = i,
            .j = j,
            .direction = direction,
        };
    }

    pub fn move(self: *Guard) void {
        const nextPos = getNextPos(self);
        self.i = nextPos[0];
        self.j = nextPos[1];
    }

    pub fn turn(self: *Guard) !void {
        const dirInt: u8 = @intFromEnum(self.direction);
        const newDirInt: u8 = try std.math.mod(u8, dirInt + 1, 4);
        self.direction = @enumFromInt(newDirInt);
    }

    pub fn getNextPos(self: *Guard) [2]usize {
        var nextPos: [2]usize = [2]usize{ self.i, self.j };

        switch (self.direction) {
            Direction.Up => nextPos[0] -= 1, // Move up decreases the i-coordinate
            Direction.Right => nextPos[1] += 1, // Move right increases the j-coordinate
            Direction.Down => nextPos[0] += 1, // Move down increases the i-coordinate
            Direction.Left => nextPos[1] -= 1, // Move left decreases the j-coordinate
        }

        return nextPos;
    }
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const allocator = std.heap.page_allocator;
    var map = std.ArrayList([]u8).init(allocator);
    defer map.deinit();

    var guard: Guard = undefined;
    var startI: usize = undefined;
    var startJ: usize = undefined;

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const copy = try allocator.dupe(u8, line);
        try map.append(copy);
        //std.debug.print("line {s}\n", .{line});
    }

    for (0..map.items.len) |i| {
        for (0..map.items[0].len) |j| {
            if (map.items[i][j] == '^') {
                startI = i;
                startJ = j;

                map.items[i][j] = 'X';
                guard = Guard.init(i, j, Direction.Up);
            }
        }
    }

    var xPositions = std.ArrayList([2]usize).init(allocator);

    while (guard.i > 0 and
        guard.i < map.items.len and
        guard.j > 0 and
        guard.j < map.items[0].len)
    {
        const nextPos = guard.getNextPos();
        const nextPosI: usize = nextPos[0];
        const nextPosJ: usize = nextPos[1];

        if (nextPosI > 0 and
            nextPosI < map.items.len and
            nextPosJ > 0 and
            nextPosJ < map.items[0].len)
        {
            //nextPos is within the bounds of the double array
            if (map.items[nextPosI][nextPosJ] == '#') {
                //encountered a wall
                try guard.turn();
            } else {
                //open space
                guard.move();

                //map.items[nextPosI][nextPosJ] = 'X';
                try xPositions.append([2]usize{ nextPosI, nextPosJ });
            }
        } else { //nextPos is not within the bounds of the double array
            guard.move();
        }
    }

    //reset the guard
    guard.i = startI;
    guard.j = startJ;
    guard.direction = Direction.Up;

    var loops: u32 = 0;

    std.debug.print("num of times to loop {d}\n", .{xPositions.items.len});
    for (xPositions.items, 0..xPositions.items.len) |xPos, index| {
        const xPosI = xPos[0];
        const xPosJ = xPos[1];

        //starting loop of adding barriers
        std.debug.print("loop {d}\n", .{index});

        var copyList = try copyArrayList(&map);
        defer {
            copyList.deinit();
            guard.i = startI;
            guard.j = startJ;
            guard.direction = Direction.Up;
        }

        if (xPosI == startI and xPosJ == startJ) continue;

        std.debug.print("placing 0 at {d},{d}\n", .{ xPosI, xPosJ });
        copyList.items[xPosI][xPosJ] = '0';

        //going to cheat a little bit and just set a really high loop number
        //if it doesn't break before the loop ends, pretty sure the guard is caught in a loop

        //real way would probably be to detect if the guard comes across a position where's he's already gone up and down

        //actual real way is to keep a map of points along with their direction
        var pointsWithDirs = std.AutoHashMap([2]usize, std.ArrayList(u8)).init(allocator);
        defer {
            var it = pointsWithDirs.valueIterator();
            while (it.next()) |entry| {
                entry.deinit();
            }
            pointsWithDirs.deinit();
        }
        var loopFound: bool = false;
        while (guard.i > 0 and
            guard.i < map.items.len and
            guard.j > 0 and
            guard.j < map.items[0].len)
        {
            // if (index == 20) {
            //     std.debug.print("printing map\n", .{});
            //     for (copyList.items) |line| {
            //         std.debug.print("{s}\n", .{line});
            //     }
            // }
            // if (index == 248 or index == 395) {
            //     loopFound = true;
            //     break;
            // }

            const nextPos = guard.getNextPos();
            const nextPosI: usize = nextPos[0];
            const nextPosJ: usize = nextPos[1];

            if (nextPosI > 0 and
                nextPosI < map.items.len and
                nextPosJ > 0 and
                nextPosJ < map.items[0].len)
            {
                var iter = pointsWithDirs.iterator();
                while (iter.next()) |i| {
                    if (i.key_ptr.*[0] == 33 and index == 20) {
                        std.debug.print("--- key: {d},{d}\n", .{ i.key_ptr.*[0], i.key_ptr.*[1] });
                        std.debug.print("--- values:\n", .{});
                        for (i.value_ptr.*.items) |item| {
                            std.debug.print("-----{d}\n", .{item});
                        }
                    }
                }

                //nextPos is within the bounds of the double array
                if (copyList.items[nextPosI][nextPosJ] == '#' or copyList.items[nextPosI][nextPosJ] == '0') {
                    if (index == 3) std.debug.print("turning, current pos symbol is {c}\n", .{copyList.items[guard.i][guard.j]});
                    //encountered a wall

                    try guard.turn();

                    if (pointsWithDirs.get(.{ guard.i, guard.j })) |dirs| {
                        if (index == 20) {
                            std.debug.print("found dirs for pos {d},{d}\n", .{ guard.i, guard.j });
                            for (dirs.items) |dir| {
                                std.debug.print("dir {d}, ", .{(dir)});
                            }
                            std.debug.print("\n", .{});
                            std.debug.print("current dir {d}\n", .{@intFromEnum(guard.direction)});
                        }
                        for (dirs.items) |dir| {
                            if (dir == @intFromEnum(guard.direction)) {
                                std.debug.print("encountered loop\n", .{});
                                loopFound = true;
                                break;
                            }
                        }

                        var dirsDupe = std.ArrayList(u8).init(allocator);
                        defer dirs.deinit();

                        std.debug.print("dirs items: ", .{});
                        for (dirs.items) |item| {
                            std.debug.print("{d}, ", .{item});
                            try dirsDupe.append(item);
                        }
                        std.debug.print("\n", .{});

                        const removed = pointsWithDirs.remove(.{ guard.i, guard.j });
                        std.debug.print("removed? {}\n", .{removed});

                        try dirsDupe.append(@intFromEnum(guard.direction));

                        std.debug.print("dirsDupe items: ", .{});
                        for (dirsDupe.items) |item| {
                            std.debug.print("{d}, ", .{item});
                        }
                        std.debug.print("\n", .{});

                        try pointsWithDirs.put(.{ guard.i, guard.j }, dirsDupe);

                        std.debug.print("hashMap items: ", .{});
                        if (pointsWithDirs.get(.{ guard.i, guard.j })) |items| {
                            std.debug.print("able to get entry\n", .{});
                            for (items.items) |item| {
                                std.debug.print("{d}, ", .{item});
                            }
                            std.debug.print("\n", .{});
                        } else std.debug.print("not able to get entry\n", .{});
                    } else {
                        var dirs = std.ArrayList(u8).init(allocator);
                        try dirs.append(@intFromEnum(guard.direction));
                        try pointsWithDirs.put(.{ guard.i, guard.j }, dirs);
                    }
                    //get the new nextPos
                    //if it's a symbol that matches the symbol you would be drawing, then it's a loop

                    copyList.items[guard.i][guard.j] = '+';
                } else {
                    //open space
                    guard.move();

                    if (copyList.items[nextPosI][nextPosJ] != '+') {
                        switch (guard.direction) {
                            Direction.Up => copyList.items[nextPosI][nextPosJ] = '^', // Move up decreases the i-coordinate
                            Direction.Right => copyList.items[nextPosI][nextPosJ] = '>', // Move right increases the j-coordinate
                            Direction.Down => copyList.items[nextPosI][nextPosJ] = 'V', // Move down increases the i-coordinate
                            Direction.Left => copyList.items[nextPosI][nextPosJ] = '<', // Move left decreases the j-coordinate
                        }
                    }

                    if (pointsWithDirs.get(.{ nextPosI, nextPosI })) |dirs| {
                        if (index == 20) {
                            std.debug.print("found dirs for pos {d},{d}\n", .{ nextPosI, nextPosJ });
                            for (dirs.items) |dir| {
                                std.debug.print("dir {d}, ", .{dir});
                            }
                            std.debug.print("\n", .{});
                            std.debug.print("current dir {d}\n", .{@intFromEnum(guard.direction)});
                        }
                        for (dirs.items) |dir| {
                            if (dir == @intFromEnum(guard.direction)) {
                                std.debug.print("encountered loop\n", .{});
                                loopFound = true;
                                break;
                            }

                            var dirsDupe = std.ArrayList(u8).init(allocator);
                            defer dirs.deinit();

                            std.debug.print("dirs items: ", .{});
                            for (dirs.items) |item| {
                                std.debug.print("{d}, ", .{item});
                                try dirsDupe.append(item);
                            }
                            std.debug.print("\n", .{});

                            const removed = pointsWithDirs.remove(.{ nextPosI, nextPosJ });
                            std.debug.print("removed? {}\n", .{removed});

                            try dirsDupe.append(@intFromEnum(guard.direction));

                            std.debug.print("dirsDupe items: ", .{});
                            for (dirsDupe.items) |item| {
                                std.debug.print("{d}, ", .{item});
                            }
                            std.debug.print("\n", .{});

                            try pointsWithDirs.put(.{ nextPosI, nextPosJ }, dirsDupe);

                            // std.debug.print("hashMap items: ", .{});
                            // for (pointsWithDirs.get(.{ nextPosI, nextPosI }).?.items) |item| {
                            //     std.debug.print("{d}, ", .{item});
                            // }
                            // std.debug.print("\n", .{});
                        }
                    } else {
                        var dirs = std.ArrayList(u8).init(allocator);
                        try dirs.append(@intFromEnum(guard.direction));
                        try pointsWithDirs.put(.{ nextPosI, nextPosJ }, dirs);
                    }
                }
            } else { //nextPos is not within the bounds of the double array
                guard.move();
            }
            if (loopFound) break;
        }

        // std.debug.print("printing map after\n", .{});
        // for (copyList.items) |line| {
        //     std.debug.print("{s}\n", .{line});
        // }

        if (loopFound) {
            std.debug.print("loop found\n", .{});
            loops += 1;
        } else {
            std.debug.print("not a loop\n", .{});
        }
    }
    std.debug.print("loops {d}\n", .{loops});

    // for (0..map.items.len) |i| {
    //     for (0..map.items[0].len) |j| {
    //         //starting loop of adding barriers
    //         std.debug.print("loop {d}\n", .{(i * map.items[0].len) + j + 1});

    //         var copyList = try copyArrayList(&map);
    //         defer {
    //             copyList.deinit();
    //             guard.i = startI;
    //             guard.j = startJ;
    //             guard.direction = Direction.Up;
    //         }

    //         if (copyList.items[i][j] == '#') continue;
    //         if (i == startI and j == startJ) continue;

    //         copyList.items[i][j] = '0';

    //         //going to cheat a little bit and just set a really high loop number
    //         //if it doesn't break before the loop ends, pretty sure the guard is caught in a loop

    //         //real way would probably be to detect if the guard comes across a position where's he's already gone up and down
    //         var loopFound: bool = false;
    //         while (guard.i > 0 and
    //             guard.i < map.items.len and
    //             guard.j > 0 and
    //             guard.j < map.items[0].len)
    //         {
    //             if (i == 0 and j == 0) {
    //                 std.debug.print("printing map\n", .{});
    //                 for (copyList.items) |line| {
    //                     std.debug.print("{s}\n", .{line});
    //                 }
    //             }

    //             const nextPos = guard.getNextPos();
    //             const nextPosI: usize = nextPos[0];
    //             const nextPosJ: usize = nextPos[1];

    //             if (nextPosI > 0 and
    //                 nextPosI < map.items.len and
    //                 nextPosJ > 0 and
    //                 nextPosJ < map.items[0].len)
    //             {
    //                 //nextPos is within the bounds of the double array
    //                 if (copyList.items[nextPosI][nextPosJ] == '#' or copyList.items[nextPosI][nextPosJ] == '0') {
    //                     //std.debug.print("encountered a wall\n", .{});
    //                     //encountered a wall
    //                     try guard.turn();
    //                     if (copyList.items[guard.i][guard.j] == '+') {
    //                         //retreading the same path, loop
    //                         std.debug.print("it really never gets here?", .{});
    //                         loopFound = true;
    //                         break;
    //                     } else copyList.items[guard.i][guard.j] = '+';
    //                 } else {
    //                     //open space
    //                     guard.move();

    //                     if (guard.direction == Direction.Up or guard.direction == Direction.Down) copyList.items[nextPosI][nextPosJ] = '|';
    //                     if (guard.direction == Direction.Left or guard.direction == Direction.Right) copyList.items[nextPosI][nextPosJ] = '-';
    //                 }
    //             } else { //nextPos is not within the bounds of the double array
    //                 guard.move();
    //             }
    //         }

    //         if (loopFound) {
    //             std.debug.print("loop found\n", .{});
    //             loops += 1;
    //         } else {
    //             std.debug.print("not a loop\n", .{});
    //         }
    //     }

    // while (guard.i > 0 and
    //     guard.i < map.items.len and
    //     guard.j > 0 and
    //     guard.j < map.items[0].len)
    // {
    //     const nextPos = guard.getNextPos();
    //     const nextPosI: usize = nextPos[0];
    //     const nextPosJ: usize = nextPos[1];

    //     if (nextPosI > 0 and
    //         nextPosI < map.items.len and
    //         nextPosJ > 0 and
    //         nextPosJ < map.items[0].len)
    //     {
    //         //nextPos is within the bounds of the double array
    //         if (map.items[nextPosI][nextPosJ] == '#') {
    //             //encountered a wall
    //             try guard.turn();
    //             map.items[guard.i][guard.j] = '+';
    //         } else {
    //             //open space
    //             guard.move();

    //             if (guard.direction == Direction.Up or guard.direction == Direction.Down) map.items[nextPosI][nextPosJ] = '|';
    //             if (guard.direction == Direction.Left or guard.direction == Direction.Right) map.items[nextPosI][nextPosJ] = '-';
    //         }
    //     } else { //nextPos is not within the bounds of the double array
    //         guard.move();
    //     }
    // }

    // var xTotal: u32 = 0;
    // for (0..map.items.len) |i| {
    //     std.debug.print("{s}\n", .{map.items[i]});
    //     for (0..map.items[0].len) |j| {
    //         if (map.items[i][j] == 'X') {
    //             xTotal += 1;
    //         }
    //     }
    // }

    // std.debug.print("xTotal {d}\n", .{xTotal});

    // std.debug.print("loops {d}\n", .{loops});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

fn copyArrayList(original: *std.ArrayList([]u8)) !std.ArrayList([]u8) {
    const allocator = std.heap.page_allocator;
    var newList = std.ArrayList([]u8).init(allocator);
    for (original.items) |item| {
        // Duplicate each item and append to the new list
        const duplicatedItem = try allocator.dupe(u8, item);
        try newList.append(duplicatedItem);
    }
    return newList;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
