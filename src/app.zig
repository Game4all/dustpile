const std = @import("std");
const graphics = @import("graphics.zig");
const glfw = @import("glfw");

pub const Application = struct {
    window: glfw.Window,
    // render resources
    renderFramebuffer: graphics.Framebuffer,
    renderTexture: graphics.Texture,
    drawPipeline: graphics.ComputePipeline,
    // world simulation resources
    // worldTexture: graphics.Texture,
    // simPipeline: graphics.ComputePipeline,
    // brushPipeline: graphics.ComputePipeline,
    // global uniforms
    // globals:

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const window = glfw.Window.create(800, 600, "dustpile", null, null, .{
            .context_version_major = 4,
            .context_version_minor = 5,
        });

        if (window == null)
            return error.WindowCreationFailed;

        try graphics.loadOpenGL(window.?);

        const renderTexture = graphics.Texture.init(800, 600, graphics.gl.RGBA8);
        const renderFramebuffer = graphics.Framebuffer.init(&renderTexture);

        return .{ .window = window.?, .renderFramebuffer = renderFramebuffer, .renderTexture = renderTexture, .drawPipeline = try graphics.ComputePipeline.init("shaders/draw.comp", allocator) };
    }

    pub fn run(app: *@This()) void {
        while (!app.window.shouldClose()) {
            glfw.pollEvents();
            var size = app.window.getSize();
            app.drawPipeline.use();
            app.renderTexture.bind_image(0, graphics.gl.WRITE_ONLY);
            app.drawPipeline.dispatch(120, 95, 1);
            app.renderFramebuffer.blit(0, @intCast(size.width), @intCast(size.height));
            app.window.swapBuffers();
        }
    }
};
