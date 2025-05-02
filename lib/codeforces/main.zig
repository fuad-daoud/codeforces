const std = @import("std");
const Codeforces = @import("client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = Codeforces.Client.init(allocator);
    defer client.deinit();

    // Get contest list
    var contests_json = try client.getContestList();
    defer allocator.free(contests_json);

    // Print the first 200 bytes of the response
    const print_len = @min(contests_json.len, 200);
    std.log.debug("First {d} bytes of response:\n{s}\n", .{ print_len, contests_json[0..print_len] });

    // Parse the JSON
    const json_parse_options = std.json.ParseOptions{
        .ignore_unknown_fields = true,
    };

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, contests_json, json_parse_options);
    defer parsed.deinit();

    std.log.debug("API json: {s}\n", .{contests_json});
    // Print the status field to verify successful parsing
    const status = parsed.value.object.get("status").?.string;
    std.log.debug("API Status: {s}\n", .{status});

    // Count the number of contests
    const contests = parsed.value.object.get("result").?.array;
    std.log.debug("Number of contests: {d}\n", .{contests.items.len});
}
