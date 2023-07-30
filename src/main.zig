const std = @import("std");
const app = @import("app.zig");
const glfw = @import("glfw");

pub fn main() !void {
    _ = glfw.init(.{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    var application = try app.Application.init(alloc);
    application.run();
    glfw.terminate();
}
