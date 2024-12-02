//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit = gpa.deinit();
        if (deinit == .leak) @panic("MEMORY LEAK"); 
    }
    
    var nums1 = std.ArrayList(u32).init(allocator);
    var nums2 = std.ArrayList(u32).init(allocator);
    defer {
        nums1.deinit();
        nums2.deinit();
    }

    var file = try std.fs.cwd().openFile("src/input.txt", .{});
    defer file.close();

    var buffReader = std.io.bufferedReader(file.reader());
    var inStream = buffReader.reader();

    var buf: [1024]u8 = undefined;
    while (try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.splitSequence(u8, line, " ");
        
        var listIndicator: i8 = 1;
        while(iter.next()) |part| {
            if(isWhitespace(part)) continue;
            
            const num = try std.fmt.parseInt(u32, part, 10);
            if(@mod(listIndicator, 2) == 1) {
            //if(listIndicator % 2 == 1) {
                //indicator is odd, add to list 1
                try nums1.append(num);
            } else {
                //indicator is even, add to list 2 
                try nums2.append(num);
            }
            listIndicator += 1;
        }
    }
    
    std.mem.sort(u32, nums1.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, nums2.items, {}, std.sort.asc(u32));
    
    if(nums1.items.len != nums2.items.len) @panic("Somehow lists are different sizes");
    
    var total: u128 = 0;
    for (nums1.items, nums2.items) |n1, n2| {
        const n1_64: u64 = n1;
        const n2_64: u64 = n2;
        const diff: u64 = if (n1_64 > n2_64) n1_64 - n2_64 else n2_64 - n1_64;
        total += diff;
        
        std.debug.print("n1 = {d}, n2 = {d}, diff = {d}\n", .{n1, n2, diff});
    }
    
    std.debug.print("total is {d}\n", .{total});
    
    var similarityScore: u128 = 0; 
    for(nums1.items) |num| {
        const occurrences: usize = countOccurrences(nums2, num);
        const score: u64 = num * occurrences;
        similarityScore += score;
        
        std.debug.print("num = {d}, occurrences = {d}, score = {d}, similarity = {d}\n", .{num, occurrences, score, similarityScore});
    }
    
    std.debug.print("similarity score is {d}\n", .{similarityScore});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!
}

pub inline fn isWhitespace(str: []const u8) bool {
    const trimmed = std.mem.trim(u8, str, &std.ascii.whitespace);
    return trimmed.len == 0;
}

pub fn countOccurrences(list: std.ArrayList(u32), target: u32) usize {
    var count: usize = 0;
    for (list.items) |item| {
        if(item == target) count += 1; 
    }
    return count;
}
