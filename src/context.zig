//TODO: rename this to be data transformers or something
const std = @import("std");
const Client = @import("client.zig");
const App = @import("app.zig");
const log = std.log.scoped(.context);

pub const Context = @This();

client: Client,
allocator: std.mem.Allocator,
app: *App,

pub fn init(
    allocator: std.mem.Allocator,
    client: Client,
    app: *App,
) !Context {
    return .{
        .allocator = allocator,
        .client = client,
        .app = app,
    };
}
pub fn deinit(self: *Context) void {
    self.client.deinit();
}

fn getContestList(self: *Context) ![]const u8 {
    const endpoint = "/contest.list";
    if (self.app.get(endpoint)) |data| {
        log.info("cached {s}", .{endpoint});
        return data;
    }
    const json = try self.client.get(endpoint);
    log.debug("contest.list json: {s}", .{json});
    try self.app.put(endpoint, json);
    return json;
}

fn getUserStatus(self: *Context, handle: []const u8) ![]u8 {
    const endpoint = try std.fmt.allocPrint(self.client.allocator, "/user.status?handle={s}", .{handle});
    if (self.app.get(endpoint)) |data| {
        log.info("cached {s}", .{endpoint});
        return data;
    }
    const json = try self.client.get(endpoint);
    log.debug("user.status json: {s}", .{json});
    try self.app.put(endpoint, json);
    return json;
}

pub const Problem = struct { solved: []const u8, unsolved: []const u8 };
pub const Contest = struct { name: []const u8, link: []const u8, problems: []const Problem };
pub const Data = struct { handles: []const []const u8, contests: []const Contest };
pub fn getContestsInfo(self: *Context, handles: []const []const u8) !Data {
    _ = try self.getContestList();
    return .{
        .handles = handles,
        .contests = &[_]Contest{
            .{
                .name = "Educational Codeforces Round 178 (Rated for Div. 2)",
                .link = "https://codeforces.com/contest/2104",
                .problems = &[_]Problem{ .{ .solved = "ABC", .unsolved = "ABCD" }, .{ .solved = "ABC", .unsolved = "ABCD" } },
            },

            .{
                .name = "Educational Codeforces Round 178 (Rated for Div. 2)",
                .link = "https://codeforces.com/contest/2104",
                .problems = &[_]Problem{ .{ .solved = "ABC", .unsolved = "ABCD" }, .{ .solved = "ABC", .unsolved = "ABCD" } },
            },
            .{
                .name = "Educational Codeforces Round 178 (Rated for Div. 2)",
                .link = "https://codeforces.com/contest/2104",
                .problems = &[_]Problem{ .{ .solved = "ABC", .unsolved = "ABCD" }, .{ .solved = "ABC", .unsolved = "ABCD" } },
            },
            .{
                .name = "Educational Codeforces Round 178 (Rated for Div. 2)",
                .link = "https://codeforces.com/contest/2104",
                .problems = &[_]Problem{ .{ .solved = "ABC", .unsolved = "ABCD" }, .{ .solved = "ABC", .unsolved = "ABCD" } },
            },
            .{
                .name = "Educational Codeforces Round 178 (Rated for Div. 2)",
                .link = "https://codeforces.com/contest/2104",
                .problems = &[_]Problem{ .{ .solved = "ABC", .unsolved = "ABCD" }, .{ .solved = "ABC", .unsolved = "ABCD" } },
            },
        },
    };
}
