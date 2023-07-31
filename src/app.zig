const std = @import("std");
const graphics = @import("graphics.zig");
const glfw = @import("glfw");

/// The serializable application state.
pub const ApplicationState = struct { brushPos: [2]i32, brushSize: f32, inputState: i32 };

pub const Application = struct {
    window: glfw.Window,
    // render resources
    renderFramebuffer: graphics.Framebuffer,
    renderTexture: graphics.Texture,
    drawPipeline: graphics.ComputePipeline,
    // world simulation resources
    worldTexture: graphics.Texture,
    // simPipeline: graphics.ComputePipeline,
    // brushPipeline: graphics.ComputePipeline,
    // global uniforms
    brushSize: i32 = 1,
    currentMaterial: i32 = 1,
    globals: graphics.UniformBuffer(ApplicationState),

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const window = glfw.Window.create(800, 600, "dustpile", null, null, .{
            .context_version_major = 4,
            .context_version_minor = 5,
        });

        if (window == null)
            return error.WindowCreationFailed;

        try graphics.loadOpenGL(window.?);

        const worldTexture = graphics.Texture.init(800, 600, graphics.gl.RGBA8);

        const renderTexture = graphics.Texture.init(800, 600, graphics.gl.RGBA8);
        const renderFramebuffer = graphics.Framebuffer.init(&renderTexture);
        const drawPipeline = try graphics.ComputePipeline.init("shaders/draw.comp", allocator);
        var uniforms = graphics.UniformBuffer(ApplicationState).init();
        uniforms.bind(drawPipeline.program, 3, "globals");

        return Application{ .window = window.?, .renderFramebuffer = renderFramebuffer, .renderTexture = renderTexture, .drawPipeline = drawPipeline, .worldTexture = worldTexture, .globals = uniforms };
    }

    /// Called when the window is resized.
    pub fn on_resize(win: glfw.Window, width: u32, height: u32) void {
        var app = win.getUserPointer(Application).?;

        // recreate the render texture and framebuffer
        app.renderFramebuffer.deinit();
        app.renderTexture.deinit();
        app.worldTexture.deinit();
        app.worldTexture = graphics.Texture.init(@intCast(width), @intCast(height), graphics.gl.RGBA8);
        app.renderTexture = graphics.Texture.init(@intCast(width), @intCast(height), graphics.gl.RGBA8);
        app.renderFramebuffer = graphics.Framebuffer.init(&app.renderTexture);

        graphics.gl.viewport(0, 0, @intCast(width), @intCast(height));
    }

    pub fn on_scroll(win: glfw.Window, width: f64, height: f64) void {
        _ = width;
        var app = win.getUserPointer(Application).?;
        app.brushSize = @max(1, app.brushSize + @as(i32, @intFromFloat(height)));
        std.log.debug("Brush size: {}", .{app.brushSize});
    }

    pub fn on_key(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
        _ = mods;
        _ = scancode;

        switch (action) {
            .release => return,
            .repeat => return,
            else => {},
        }

        var app: *Application = window.getUserPointer(Application).?;
        switch (key) {
            .zero => app.currentMaterial = 0,
            .one => app.currentMaterial = 1,
            .two => app.currentMaterial = 2,
            .three => app.currentMaterial = 3,
            .four => app.currentMaterial = 4,
            .five => app.currentMaterial = 5,
            .six => app.currentMaterial = 6,
            .seven => app.currentMaterial = 7,
            .eight => app.currentMaterial = 8,
            .nine => app.currentMaterial = 9,
            // .space => {
            //      app.simState = 1 - app.simState;
            //     std.log.debug("Simulation state is now {}", .{app.simState});
            // },
            else => {},
        }
    }

    pub fn update(app: *@This()) void {
        // updating the globals
        var size = app.window.getSize();
        var pos = app.window.getCursorPos();
        const inputState: i32 = @as(i32, @intFromBool(app.window.getMouseButton(glfw.MouseButton.right) == glfw.Action.press)) << 2 | @as(i32, @intFromBool(app.window.getMouseButton(glfw.MouseButton.middle) == glfw.Action.press)) << 1 | @as(i32, @intFromBool(app.window.getMouseButton(glfw.MouseButton.left) == glfw.Action.press));
        app.globals.update(ApplicationState{
            .brushPos = [2]i32{ @intFromFloat(pos.xpos), @as(i32, @intCast(size.height)) - @as(i32, @intFromFloat(pos.ypos)) },
            .brushSize = @floatFromInt(app.brushSize),
            .inputState = inputState,
        });
    }

    // Draw the world to the render texture and then blit it to the screen.
    pub fn draw(app: *@This()) void {
        var size = app.window.getSize();
        app.drawPipeline.use();
        app.renderTexture.bind_image(0, graphics.gl.WRITE_ONLY);

        const workgroupSize = app.drawPipeline.getWorkgroupSize();
        app.drawPipeline.dispatch(@intFromFloat(@ceil(@as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(workgroupSize[0])))), @intFromFloat(@ceil(@as(f32, @floatFromInt(size.height)) / @as(f32, @floatFromInt(workgroupSize[1])))), workgroupSize[2]);
        app.renderFramebuffer.blit(0, @intCast(size.width), @intCast(size.height));
    }

    pub fn run(app: *@This()) void {
        app.window.setUserPointer(app);
        app.window.setFramebufferSizeCallback(Application.on_resize);
        app.window.setScrollCallback(Application.on_scroll);
        app.window.setKeyCallback(Application.on_key);
        app.window.setInputMode(glfw.Window.InputMode.cursor, glfw.Window.InputModeCursor.hidden);
        while (!app.window.shouldClose()) {
            glfw.pollEvents();
            app.update();
            app.draw();
            app.window.swapBuffers();
        }
    }
};
