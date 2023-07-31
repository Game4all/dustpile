const std = @import("std");
const Application = @import("app.zig").Application;
const glfw = @import("glfw");

pub fn main() !void {
    _ = glfw.init(.{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    var application = try Application.init(alloc);
    application.run();
    glfw.terminate();
    _ = gpa.deinit();
}
