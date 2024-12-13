const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    const allocator = std.heap.page_allocator;

    var inputDoubleArray = std.ArrayList([]u8).init(allocator);
    var antiNodes = std.ArrayList([]u8).init(allocator);

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const dupe1 = try allocator.dupe(u8, line);
        try inputDoubleArray.append(dupe1);
        const dupe2 = try allocator.dupe(u8, line);
        try antiNodes.append(dupe2);
    }

    //var antiNodesCount: u32 = 0;
    for (0..inputDoubleArray.items.len) |targI| {
        for (0..inputDoubleArray.items[0].len) |targJ| {
            //get target character
            if (inputDoubleArray.items[targI][targJ] != '.') {
                //found target char
                for (0..antiNodes.items.len) |i| {
                    print("{s}\n", .{antiNodes.items[i]});
                }

                const target = inputDoubleArray.items[targI][targJ];
                print("target {c} found at {d},{d}\n", .{ target, targI, targJ });

                //look for more of the target
                for (0..inputDoubleArray.items.len) |i| {
                    for (0..inputDoubleArray.items[0].len) |j| {
                        if (i == targI and j == targJ) continue;

                        if (inputDoubleArray.items[i][j] == target) {
                            const i_isize: i64 = @intCast(i);
                            const j_isize: i64 = @intCast(j);
                            const targI_isize: i64 = @intCast(targI);
                            const targJ_isize: i64 = @intCast(targJ);

                            const iOffset: i64 = i_isize - targI_isize;
                            const jOffset: i64 = j_isize - targJ_isize;

                            var antiNode1i: i64 = i_isize + iOffset;
                            var antiNode1j: i64 = j_isize + jOffset;

                            var antiNode2i: i64 = targI_isize - iOffset;
                            var antiNode2j: i64 = targJ_isize - jOffset;

                            antiNodes.items[i][j] = '#';
                            antiNodes.items[targI][targJ] = '#';

                            while (true) {
                                if (antiNode1i >= 0 and
                                    antiNode1i < inputDoubleArray.items.len and
                                    antiNode1j >= 0 and
                                    antiNode1j < inputDoubleArray.items[0].len)
                                {
                                    //print("anti node i and j: {d},{d} and dimensions of map: {d},{d}\n", .{ antiNode1i, antiNode1j, inputDoubleArray.items.len, inputDoubleArray.items[0].len });
                                    const anPosI: usize = @intCast(antiNode1i);
                                    const anPosJ: usize = @intCast(antiNode1j);
                                    antiNodes.items[anPosI][anPosJ] = '#';

                                    antiNode1i += iOffset;
                                    antiNode1j += jOffset;
                                } else break;
                            }

                            while (true) {
                                if (antiNode2i >= 0 and
                                    antiNode2i < inputDoubleArray.items.len and
                                    antiNode2j >= 0 and
                                    antiNode2j < inputDoubleArray.items[0].len)
                                {
                                    const anPosI: usize = @intCast(antiNode2i);
                                    const anPosJ: usize = @intCast(antiNode2j);
                                    antiNodes.items[anPosI][anPosJ] = '#';

                                    antiNode2i -= iOffset;
                                    antiNode2j -= jOffset;
                                } else break;
                            }
                        }
                    }
                }
            }
        }
    }

    var antiNodesCount: u32 = 0;
    for (0..antiNodes.items.len) |i| {
        print("{s}\n", .{antiNodes.items[i]});
        for (0..antiNodes.items[0].len) |j| {
            if (antiNodes.items[i][j] == '#') antiNodesCount += 1;
        }
    }

    print("antiNodesCount {d}\n", .{antiNodesCount});

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
