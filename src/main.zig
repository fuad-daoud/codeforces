const std = @import("std");
const builtin = @import("builtin");
const httpz = @import("httpz");
const Client = @import("client.zig");
const Context = @import("context.zig");
const Template = @import("template.zig");
const Handlers = @import("handlers.zig");
const App = @import("app.zig");

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

    // 10s
    var app = try App.init(allocator, 10);

    var server = try httpz.Server(*App).init(allocator, .{ .port = port, .address = "0.0.0.0" }, &app);
    defer {
        log.info("shutting down server", .{});
        app.deinit();
        server.stop();
        server.deinit();
        log.info("server down", .{});
    }

    var router = try server.router(.{});
    router.get("/", Handlers.home, .{});

    log.info("running server on {d}", .{port});
    try server.listen();
}
