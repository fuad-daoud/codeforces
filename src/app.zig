const new_cache = @import("cache_zig");
const std = @import("std");

const log = std.log.scoped(.app);

const App = @This();

pub const CacheType = new_cache.Cache(CacheValue);

pub const CacheValue = struct {
    data: []const u8,
};

cache: CacheType,
ttl: u32,

pub fn init(allocator: std.mem.Allocator, ttl: u32) !App {
    const cache = try CacheType.init(allocator, .{ .max_size = 10000 });
    return .{
        .cache = cache,
        .ttl = ttl,
    };
}

pub fn deinit(self: *App) void {
    self.cache.deinit();
}

pub fn get(self: *App, key: []const u8) ?[]const u8 {
    if (self.cache.get(key)) |cacheValue| {
        log.info("ttl: {d}", .{cacheValue.ttl()});
        defer cacheValue.release();
        return cacheValue.value.data;
    }
    return null;
}

pub fn put(self: *App, key: []const u8, data: []const u8) !void {
    try self.cache.put(key, CacheValue{ .data = data }, .{ .ttl = self.ttl });
}
