const std = @import("std");

const clientLog = std.log.scoped(.Client);
pub const Client = @This();

const MB = 1_048_576;
const headers_max_size = 2048;
const body_max_size = 1 * MB;

pub const CodeforcesError = error{
    WrongStatusResponse,
    NetworkError,
    ParseError,
};

allocator: std.mem.Allocator,
base_url: []const u8,

pub fn init(allocator: std.mem.Allocator, base_url: []const u8) Client {
    return Client{
        .allocator = allocator,
        .base_url = base_url,
    };
}

pub fn deinit(self: *Client) void {
    _ = self;
}

pub fn get(self: *Client, endpoint: []const u8) ![]u8 {
    return try self.makeRequest(try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ self.base_url, endpoint }));
}

fn makeRequest(self: *Client, url_str: []const u8) ![]u8 {
    clientLog.info("Starting {s}({s})...", .{ "makeRequest", url_str });
    defer clientLog.info("Finished {s}...", .{"makeRequest"});

    var client = std.http.Client{ .allocator = self.allocator };
    defer client.deinit();

    var hbuffer: [headers_max_size]u8 = undefined;
    const options = std.http.Client.RequestOptions{ .server_header_buffer = &hbuffer };

    const url = try std.Uri.parse(url_str);
    var request = try client.open(std.http.Method.GET, url, options);
    defer request.deinit();

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
