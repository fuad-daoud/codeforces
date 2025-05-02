const std = @import("std");
const Allocator = std.mem.Allocator;

const MB = 1_048_576;
const headers_max_size = 2048;
const body_max_size = 1 * MB; // 1MB should be enough for Codeforces responses

pub const CodeforcesError = error{
    WrongStatusResponse,
    NetworkError,
    ParseError,
};

const clientLog = std.log.scoped(.Client);

pub const Client = struct {
    allocator: Allocator,
    comptime base_url: []const u8 = "https://codeforces.com/api",

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn get(self: *Self, comptime endpoint: []const u8) ![]u8 {
        return try self.makeRequest(std.fmt.comptimePrint("{s}{s}", .{ self.base_url, endpoint }));
    }

    fn makeRequest(self: *Self, url_str: []const u8) ![]u8 {
        clientLog.info("Starting {s}({s})...", .{ "makeRequest", url_str });
        defer clientLog.info("Finished {s}...", .{"makeRequest"});
        const url = try std.Uri.parse(url_str);

        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var hbuffer: [headers_max_size]u8 = undefined;
        const options = std.http.Client.RequestOptions{ .server_header_buffer = &hbuffer };

        clientLog.info("Opening connection to {s}...", .{url_str});
        var request = try client.open(std.http.Method.GET, url, options);
        defer request.deinit();
        clientLog.info("Sending request to {s}...", .{url});

        try request.send();
        try request.finish();
        try request.wait();

        if (request.response.status != std.http.Status.ok) {
            return CodeforcesError.WrongStatusResponse;
        }

        var response_buffer = std.ArrayList(u8).init(self.allocator);
        defer response_buffer.deinit();

        var reader = request.reader();
        var buf: [4096]u8 = undefined;

        while (true) {
            const bytes_read = try reader.read(&buf);
            std.debug.print("Bytes read: {d}\n", .{bytes_read});
            if (bytes_read == 0) break;

            try response_buffer.appendSlice(buf[0..bytes_read]);
        }

        const json_parse_options = std.json.ParseOptions{
            .ignore_unknown_fields = true,
        };

        var parsed = std.json.parseFromSlice(std.json.Value, self.allocator, response_buffer.items, json_parse_options) catch {
            response_buffer.deinit();
            return CodeforcesError.ParseError;
        };
        defer parsed.deinit();

        return try self.allocator.dupe(u8, response_buffer.items);
    }

    pub fn getContestList(self: *Self) ![]u8 {
        return try self.get("/contest.list");
    }
};
