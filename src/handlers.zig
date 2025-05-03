const httpz = @import("httpz");
const std = @import("std");
const Template = @import("template.zig");
const Client = @import("client.zig");
const Context = @import("context.zig");
const App = @import("app.zig");

pub const Handlers = @This();

const log = std.log.scoped(.handlers);

pub fn home(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    log.info("starting {s}..", .{"home"});
    defer log.info("finished {s}..", .{"home"});
    const allocator = req.arena;
    var template = try Template.init(allocator, "templates/home.html");
    defer template.deinit();

    const client = Client.init(allocator, "https://codeforces.com/api");

    var context = try Context.init(allocator, client, app);
    defer context.deinit();

    const data = try context.getContestsInfo(&[_][]const u8{
        "gon",
        "immortalfox",
    });

    const result = try template.render(data);
    res.body = result;
}
