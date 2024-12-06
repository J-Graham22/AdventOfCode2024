const std = @import("std");

pub fn FixBrokenLines(line: *std.ArrayList(u32), pageMap: *std.AutoHashMap(u32, std.ArrayList(u32))) !u32 {
    var lineValid: bool = true;

    for (0..line.items.len) |i| {
        //check the numbers before to make sure they don't need to come after
        for (0..i) |j| {
            const pagesToComeAfter = pageMap.get(line.items[i]);

            if (pagesToComeAfter == null) {
                break;
            } else {
                for (pagesToComeAfter.?.items) |page| {
                    if (page == line.items[j]) {
                        lineValid = false;
                        std.debug.print("page {d} is supposed to come after page {d}\n", .{ page, line.items[j] });

                        //do the logic of swapping
                        if (i + 1 == line.items.len) {
                            std.debug.print("inserting", .{});
                            _ = try line.append(page);
                        } else {
                            _ = try line.insert(i + 1, page); //add at i+1
                        }
                        _ = line.orderedRemove(j); //remove at j

                        return 0;
                    }
                }
            }
        }

        //check the numbers after to make sure they don't need to come before
        for (i + 1..line.items.len) |j| {
            const pagesToComeAfter = pageMap.get(line.items[j]);

            if (pagesToComeAfter == null) {
                break;
            } else {
                for (pagesToComeAfter.?.items) |page| {
                    if (page == line.items[i]) {
                        lineValid = false;
                        std.debug.print("page {d} is supposed to come before page {d}\n", .{ line.items[j], line.items[i] });

                        //do the logic of swapping
                        const num = line.items[j];
                        _ = line.orderedRemove(j); //remove at j
                        _ = try line.insert(i, num); //add at i

                        return 0;
                    }
                }
            }
        }
    }

    if (lineValid) {
        // const len: f32 = @floatFromInt(numsList.items.len);
        // const middleIndex: usize = @intCast(std.math.floor(len / 2));
        const len: u32 = @intCast(line.items.len);
        const halfLen = len / 2;
        const middleIndex: usize = @intCast(halfLen);
        const middleNumber: u32 = line.items[middleIndex];
        return middleNumber;
    } else return 0;
}

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const allocator = std.heap.page_allocator;
    var pageMap = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    defer {
        var iter = pageMap.iterator();
        while (iter.next()) |i| {
            i.value_ptr.deinit();
        }
        pageMap.deinit();
    }

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var middlePageTotal: u32 = 0;

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.containsAtLeast(u8, line, 1, &[_]u8{'|'})) {
            //one of the pair lines
            var nums = std.mem.splitSequence(u8, line, "|");
            //var iter = std.mem.splitSequence(u8, line, " ");

            const pageNumberStr = nums.next();
            const pageNumberAfterStr = nums.next();

            const pageNumber = try std.fmt.parseInt(u32, pageNumberStr.?, 10);
            const pageNumberAfter = try std.fmt.parseInt(u32, pageNumberAfterStr.?, 10);

            if (pageMap.get(pageNumber)) |order| {
                var mutOrder = std.ArrayList(u32).init(allocator);
                defer order.deinit();

                mutOrder.items = order.items;

                _ = pageMap.remove(pageNumber);

                try mutOrder.append(pageNumberAfter);
                try pageMap.put(pageNumber, mutOrder);
            } else {
                //create and add
                var newList = std.ArrayList(u32).init(allocator);
                //defer newList.deinit();

                try newList.append(pageNumberAfter);
                try pageMap.put(pageNumber, newList);
            }

            std.debug.print("vals for key {d}: \n", .{pageNumber});
            const keys = pageMap.get(pageNumber);
            for (keys.?.items) |i| {
                std.debug.print("--- key {d}\n", .{i});
            }
        }

        //std.debug.print("pageMap length {d}", .{pageMap.capacity()});

        if (std.mem.containsAtLeast(u8, line, 1, &[_]u8{','})) {
            //one of the page order lines
            var nums = std.mem.splitSequence(u8, line, ",");

            var numsList = std.ArrayList(u32).init(allocator);
            defer numsList.deinit();

            while (nums.next()) |i| {
                const pageNum: u32 = try std.fmt.parseInt(u32, i, 10);
                try numsList.append(pageNum);
            }

            var lineValid: bool = true;

            for (0..numsList.items.len) |i| {
                //check the numbers before to make sure they don't need to come after
                for (0..i) |j| {
                    const pagesToComeAfter = pageMap.get(numsList.items[i]);

                    if (pagesToComeAfter == null) {
                        break;
                    } else {
                        for (pagesToComeAfter.?.items) |page| {
                            if (page == numsList.items[j]) {
                                lineValid = false;
                                std.debug.print("page {d} is supposed to come after page {d}\n", .{ page, numsList.items[j] });
                                break;
                            }
                        }
                    }
                }

                //check the numbers after to make sure they don't need to come before
                for (i + 1..numsList.items.len) |j| {
                    const pagesToComeAfter = pageMap.get(numsList.items[j]);

                    if (pagesToComeAfter == null) {
                        break;
                    } else {
                        for (pagesToComeAfter.?.items) |page| {
                            if (page == numsList.items[i]) {
                                lineValid = false;
                                std.debug.print("page {d} is supposed to come before page {d}\n", .{ page, numsList.items[i] });
                                break;
                            }
                        }
                    }
                }
            }
            if (!lineValid) {
                while (true) {
                    std.debug.print("line: ", .{});
                    for (numsList.items) |i| {
                        std.debug.print("{d}, ", .{i});
                    }
                    std.debug.print("\n", .{});

                    var middleNumVal: u32 = undefined;
                    middleNumVal = FixBrokenLines(&numsList, &pageMap) catch 0;
                    if (middleNumVal != 0) {
                        middlePageTotal += middleNumVal;
                        break;
                    }
                }
                std.debug.print("==============\n", .{});
            }

            // if (lineValid) {
            //     // const len: f32 = @floatFromInt(numsList.items.len);
            //     // const middleIndex: usize = @intCast(std.math.floor(len / 2));
            //     const len: u32 = @intCast(numsList.items.len);
            //     const halfLen = len / 2;
            //     const middleIndex: usize = @intCast(halfLen);
            //     const middleNumber: u32 = numsList.items[middleIndex];
            //     middlePageTotal += middleNumber;
            // }

            //std.debug.print("line {s}\n", .{line});
        }

        //std.debug.print("{s}\n", .{line});
        //const copy = try allocator.dupe(u8, line);
        //try crossWord.append(copy);
    }

    std.debug.print("middle Page total {d}\n", .{middlePageTotal});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
