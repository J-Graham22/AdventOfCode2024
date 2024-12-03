const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // const mulRegex = try std.regex.Regex.compile(std.heap.page_allocator, "mull\\((d{1,3},(\\d{1,3}\\)");
    // defer mulRegex.deinit();

    // const test_string = "Testing mul(234,34) and mul( 2234,) and mul(12,4e)";

    // const hasMatch = mulRegex.match(test_string);
    // std.debug.print("contains match {}\n", .{hasMatch});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().readFileAlloc(allocator, "src/input.txt", 1024 * 1024);
    defer allocator.free(file);

    std.debug.print("content = {s}\n", .{file});

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
