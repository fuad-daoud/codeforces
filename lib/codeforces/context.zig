const Codeforces = @import("client.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const beam = @import("beam");

pub fn arenaSum(array: beam.term) !u64 {
    var arena = std.heap.ArenaAllocator.init(beam.allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const slice = try beam.get([]u64, array, .{ .allocator = arena_allocator });

    var total: u64 = 0;

    for (slice) |item| {
        total += item;
    }

    return total;
}

pub fn contestList() !u8 {
    var arena = std.heap.ArenaAllocator.init(beam.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = Codeforces.Client.init(allocator);
    defer client.deinit();

    const contests_json = try client.getContestList();
    defer allocator.free(contests_json);
    //
    // // Print the first 200 bytes of the response
    // const print_len = @min(contests_json.len, 200);
    // std.log.debug("First {d} bytes of response:\n{s}\n", .{ print_len, contests_json[0..print_len] });
    //
    // // Parse the JSON
    // const json_parse_options = std.json.ParseOptions{
    //     .ignore_unknown_fields = true,
    // };
    //
    // const parsed = try std.json.parseFromSlice(std.json.Value, allocator, contests_json, json_parse_options);
    // defer parsed.deinit();
    //
    // std.log.debug("API json: {s}\n", .{contests_json});
    // // Print the status field to verify successful parsing
    // const status = parsed.value.object.get("status").?.string;
    // std.log.debug("API Status: {s}\n", .{status});
    return 0;
}
