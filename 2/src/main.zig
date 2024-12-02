const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var totalSafeRecords: u32 = 0;

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var list = std.ArrayList([]const u8).init(allocator);
        defer list.deinit();

        var iter = std.mem.splitSequence(u8, line, " ");
        while (iter.next()) |part| {
            try list.append(part);
        }

        var reportSafe: bool = try isReportSafe(list.items);
        if (reportSafe) std.debug.print("report safe\n", .{});
        if (!reportSafe) {
            for (0..list.items.len) |i| {
                var sublist = std.ArrayList([]const u8).init(allocator);
                defer sublist.deinit();

                //add all elements except this index
                for (0..list.items.len) |j| {
                    if (j != i) try sublist.append(list.items[j]);
                }

                if (try isReportSafe(sublist.items)) {
                    reportSafe = true;
                    std.debug.print("report safe on dampening\n", .{});
                    break;
                }
            }
        }

        if (reportSafe) totalSafeRecords += 1;
    }

    std.debug.print("total safe records is {d}\n", .{totalSafeRecords});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!
}

pub fn isReportSafe(report: []const []const u8) !bool {
    std.debug.print("line = {s}\n", .{report});

    var prevNum: ?u32 = null;
    var increasing: ?bool = null;
    for (report) |part| {
        const num = try std.fmt.parseInt(u32, part, 10);

        if (prevNum == null) {
            //first number
            prevNum = num;
            continue;
        }

        if (increasing == null) {
            if (num > prevNum.?) {
                increasing = true;
            } else {
                increasing = false;
            }
        }

        if (increasing.? and num < prevNum.?) return false; //should be increasing but is not
        if (!increasing.? and num > prevNum.?) return false; //should be decreasing but is not

        const diff: u32 = if (num > prevNum.?) num - prevNum.? else prevNum.? - num;
        if (diff < 1 or diff > 3) return false; //jump between values is too big

        prevNum = num;
    }

    return true;
}
