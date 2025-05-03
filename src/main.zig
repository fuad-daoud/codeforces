const std = @import("std");
const httpz = @import("httpz");
const Template = @import("template.zig");
const builtin = @import("builtin");

const log = std.log.scoped(.main);

pub fn main() !void {
    const mode = builtin.mode;

    switch (mode) {
        .Debug => log.info("Running in Debug mode", .{}),
        .ReleaseSafe => log.info("Running in ReleaseSafe mode", .{}),
        .ReleaseFast => log.info("Running in ReleaseFast mode", .{}),
        .ReleaseSmall => log.info("Running in ReleaseSmall mode", .{}),
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const port = 8080;

    var server = try httpz.Server(void).init(allocator, .{ .port = port, .address = "0.0.0.0" }, {});
    defer {
        log.info("shutting down server", .{});
        server.stop();
        server.deinit();
        log.info("server down", .{});
    }

    var router = try server.router(.{});
    router.get("/", home, .{});

    log.info("running server on {d}", .{port});
    try server.listen();
}

fn home(req: *httpz.Request, res: *httpz.Response) !void {
    log.info("starting {s}..", .{"home"});
    const allocator = req.arena;
    var template = try Template.init(allocator, "templates/home.html");
    defer template.deinit();
    const Problem = struct { solved: []const u8, unsolved: []const u8 };
    const Contest = struct { name: []const u8, link: []const u8, problems: []const Problem };

    const data = .{
        .items = &[_][]const u8{
            "gon",
            "immortalfox",
        },
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

    const result = try template.render(data);
    res.body = result;
    log.info("finished {s}..", .{"home"});
}
