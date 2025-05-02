const std = @import("std");
const beam = @import("beam");

const log = std.log.scoped(.Context);

pub const Contest = struct {
    id: i32,
    name: []const u8,
};

pub fn transformContestData(contestList: []Contest) !void {
    _ = contestList;
    log.info("Starting {s}..", .{"transformContestData"});
    defer log.info("Finished {s}..", .{"transformContestData"});
}

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
