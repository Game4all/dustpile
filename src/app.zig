const std = @import("std");
const graphics = @import("graphics.zig");
const glfw = @import("glfw");

/// The serializable application state.
pub const ApplicationState = struct { brushPos: [2]i32, inputState: i32 };

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
    globals: graphics.UniformBuffer(ApplicationState),

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
        const drawPipeline = try graphics.ComputePipeline.init("shaders/draw.comp", allocator);
        var uniforms = graphics.UniformBuffer(ApplicationState).init();
        uniforms.bind(drawPipeline.program, 3, "globals");

        return .{ .window = window.?, .renderFramebuffer = renderFramebuffer, .renderTexture = renderTexture, .drawPipeline = drawPipeline, .globals = uniforms };
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

    pub fn update(app: *@This()) void {
        var size = app.window.getSize();
        var pos = app.window.getCursorPos();
        app.globals.update(ApplicationState{
            .brushPos = [2]i32{ @intFromFloat(pos.xpos), @as(i32, @intCast(size.height)) - @as(i32, @intFromFloat(pos.ypos)) },
            .inputState = 0,
        });
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
            app.update();
            app.draw();
            app.window.swapBuffers();
        }
    }
};
