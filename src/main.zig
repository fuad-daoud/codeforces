const std = @import("std");
const httpz = @import("httpz");
const Template = @import("template.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = try httpz.Server(void).init(allocator, .{ .port = 8080 }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/", home, .{});

    try server.listen();
}

fn home(req: *httpz.Request, res: *httpz.Response) !void {
    const allocator = req.arena;

    // const template_src = @embedFile("templates/home.html");
    // const template = Template.Template.init(allocator, template_src);
    var template = try Template.Template.initFromFile(allocator, "src/templates/home.html");
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
}
