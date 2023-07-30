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

    /// Called when the window is resized.
    pub fn on_resize(win: glfw.Window, width: u32, height: u32) void {
        var app = win.getUserPointer(Application).?;

        // recreate the render texture and framebuffer
        app.renderFramebuffer.deinit();
        app.renderTexture.deinit();
        app.renderTexture = graphics.Texture.init(@intCast(width), @intCast(height), graphics.gl.RGBA8);
        app.renderFramebuffer = graphics.Framebuffer.init(&app.renderTexture);

        graphics.gl.viewport(0, 0, @intCast(width), @intCast(height));
    }

    // Draw the world to the render texture and then blit it to the screen.
    pub fn draw(app: *@This()) void {
        var size = app.window.getSize();
        app.drawPipeline.use();
        app.renderTexture.bind_image(0, graphics.gl.WRITE_ONLY);
        app.drawPipeline.dispatch(120, 95, 1);
        app.renderFramebuffer.blit(0, @intCast(size.width), @intCast(size.height));
    }

    pub fn run(app: *@This()) void {
        app.window.setUserPointer(app);
        app.window.setFramebufferSizeCallback(Application.on_resize);
        while (!app.window.shouldClose()) {
            glfw.pollEvents();
            app.draw();
            app.window.swapBuffers();
        }
    }
};
