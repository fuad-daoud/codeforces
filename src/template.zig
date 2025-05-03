const std = @import("std");
const builtin = @import("builtin");

pub const Template = struct {
    allocator: std.mem.Allocator,
    content: []const u8,
    owned: bool,

    pub fn init(allocator: std.mem.Allocator, comptime content: []const u8) !Template {
        if (builtin.mode == .ReleaseSafe) {
            return .{
                .allocator = allocator,
                .content = @embedFile(content),
                .owned = false,
            };
        }

        return try initFromFile(allocator, "src/" ++ content);
    }

    fn initFromFile(allocator: std.mem.Allocator, path: []const u8) !Template {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 1024 * 1024); // 1MB max

        return .{
            .allocator = allocator,
            .content = content,
            .owned = true,
        };
    }

    pub fn deinit(self: *Template) void {
        if (self.owned) {
            self.allocator.free(self.content);
        }
    }

    pub fn render(self: Template, data: anytype) ![]const u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        try self.renderContent(&result, self.content, data);
        return result.toOwnedSlice();
    }

    fn renderContent(self: Template, result: *std.ArrayList(u8), content: []const u8, context: anytype) !void {
        var i: usize = 0;

        while (i < content.len) {
            // Handle {{#each items}} ... {{/each}} loops
            if (std.mem.startsWith(u8, content[i..], "{{#each ")) {
                // Find the matching {{/each}} tag
                var depth: usize = 1;
                var j: usize = i + 1;
                var end_tag_pos: ?usize = null;

                while (j < content.len and depth > 0) {
                    if (std.mem.startsWith(u8, content[j..], "{{#each ")) {
                        depth += 1;
                    } else if (std.mem.startsWith(u8, content[j..], "{{/each}}")) {
                        depth -= 1;
                        if (depth == 0) {
                            end_tag_pos = j;
                            break;
                        }
                    }
                    j += 1;
                }

                if (end_tag_pos == null) {
                    return error.UnclosedEachTag;
                }

                const end_pos = end_tag_pos.?;

                // Extract the field name
                const start_content = std.mem.indexOf(u8, content[i..], " ") orelse
                    return error.InvalidEachSyntax;
                const end_field = std.mem.indexOf(u8, content[i + start_content + 1 ..], "}}") orelse
                    return error.InvalidEachSyntax;
                const field_name = content[i + start_content + 1 .. i + start_content + 1 + end_field];

                // Get the loop content
                const loop_start = std.mem.indexOf(u8, content[i..], "}}") orelse
                    return error.InvalidEachSyntax;
                const loop_content = content[i + loop_start + 2 .. end_pos];

                // Check if we're dealing with a struct that has fields
                const T = @TypeOf(context);
                if (@typeInfo(T) == .@"struct") {
                    // Find the matching field in context
                    inline for (std.meta.fields(T)) |field| {
                        if (std.mem.eql(u8, field.name, field_name)) {
                            const items = @field(context, field.name);
                            for (items) |item| {
                                try self.renderContent(result, loop_content, item);
                            }
                            break;
                        }
                    }
                }

                i = end_pos + 9; // length of "{{/each}}"
            }
            // Handle {{variable}} replacements
            else if (std.mem.startsWith(u8, content[i..], "{{")) {
                const end = std.mem.indexOf(u8, content[i..], "}}") orelse
                    return error.UnclosedVariable;
                const var_name = content[i + 2 .. i + end];

                try self.replaceVariable(result, var_name, context);

                i += end + 2;
            } else {
                try result.append(content[i]);
                i += 1;
            }
        }
    }

    // Helper function to render a section with a given context
    fn renderSection(self: Template, result: *std.ArrayList(u8), content: []const u8, context: anytype) !void {
        var i: usize = 0;

        while (i < content.len) {
            if (std.mem.startsWith(u8, content[i..], "{{")) {
                const end = std.mem.indexOf(u8, content[i..], "}}") orelse
                    return error.UnclosedVariable;
                const var_name = content[i + 2 .. i + end];

                try self.replaceVariable(result, var_name, context);

                i += end + 2;
            } else {
                try result.append(content[i]);
                i += 1;
            }
        }
    }

    // Also update replaceVariable to handle non-struct types
    fn replaceVariable(self: Template, result: *std.ArrayList(u8), var_name: []const u8, context: anytype) !void {
        const T = @TypeOf(context);

        // If it's just "this" or ".", render the value itself
        if (std.mem.eql(u8, var_name, "this") or std.mem.eql(u8, var_name, ".")) {
            try self.formatValue(result, context);
            return;
        }

        // Check if type has fields (struct)
        if (@typeInfo(T) == .@"struct") {
            inline for (std.meta.fields(T)) |field| {
                if (std.mem.eql(u8, field.name, var_name)) {
                    const value = @field(context, field.name);
                    try self.formatFieldValue(result, value, field.type);
                    return;
                }
            }
        }
        // If we get here and it's not a struct, we can't access fields on it
        // This is expected for primitives like strings or numbers
    }

    // Helper function to properly format field values
    fn formatFieldValue(self: Template, result: *std.ArrayList(u8), value: anytype, comptime FieldType: type) !void {
        if (FieldType == []const u8 or FieldType == *const []u8) {
            try result.appendSlice(value);
            return;
        }

        const type_info = @typeInfo(FieldType);
        if (type_info == .pointer and
            type_info.pointer.size == .one and
            @typeInfo(type_info.pointer.child) == .array and
            @typeInfo(type_info.pointer.child).array.child == u8)
        {
            try result.appendSlice(value);
            return;
        }
        try self.formatValue(result, value);
    }

    // Helper function to properly format different types
    fn formatValue(self: Template, result: *std.ArrayList(u8), value: anytype) !void {
        const T = @TypeOf(value);

        switch (@typeInfo(T)) {
            .int, .comptime_int => {
                try result.appendSlice(try std.fmt.allocPrint(self.allocator, "{d}", .{value}));
            },
            .float, .comptime_float => {
                try result.appendSlice(try std.fmt.allocPrint(self.allocator, "{d:.2}", .{value}));
            },
            .pointer => |ptr| {
                if (ptr.size == .slice and ptr.child == u8) {
                    try result.appendSlice(value);
                } else {
                    try result.appendSlice(try std.fmt.allocPrint(self.allocator, "{any}", .{value}));
                }
            },
            else => {
                try result.appendSlice(try std.fmt.allocPrint(self.allocator, "{any}", .{value}));
            },
        }
    }
};
