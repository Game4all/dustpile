const std = @import("std");
const graphics = @import("graphics.zig");
const glfw = @import("glfw");
const materials = @import("material.zig");

/// The serializable application state.
pub const ApplicationState = struct { brushPos: [2]i32, brushSize: f32, brushType: BrushType, material: i32, inputState: i32, time: f32, simRunning: i32 };

const BrushType = enum(i32) { circle = 0, square = 1, hline = 2 };

const SimRunState = enum(i32) { step = 2, running = 1, paused = 0 };

pub const Application = struct {
    window: glfw.Window,
    // render resources
    renderFramebuffer: graphics.Framebuffer,
    renderTexture: graphics.Texture,
    drawPipeline: graphics.ComputePipeline,
    // world simulation resources
    worldTexture: graphics.Texture,
    currentWorldImageIndex: u32 = 0,
    simPipeline: graphics.ComputePipeline,
    brushPipeline: graphics.ComputePipeline,
    // global uniforms
    brushSize: i32 = 1,
    simState: SimRunState = .running,
    currentMaterial: i32 = 1,
    brushType: BrushType = .circle,
    globals: graphics.UniformBuffer(ApplicationState),
    materials: graphics.UniformBuffer(@TypeOf(materials.MATERIAL_LIST)),

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const window = glfw.Window.create(800, 600, "dustpile", null, null, .{
            .context_version_major = 4,
            .context_version_minor = 5,
            .srgb_capable = true,
        });

        if (window == null)
            return error.WindowCreationFailed;

        try graphics.loadOpenGL(window.?);

        const worldTexture = graphics.Texture.init(800, 600, graphics.gl.RGBA8I, 2);

        const renderTexture = graphics.Texture.init(800, 600, graphics.gl.RGBA8, 1);
        const renderFramebuffer = graphics.Framebuffer.init(&renderTexture);
        const drawPipeline = try graphics.ComputePipeline.init("shaders/draw.comp", allocator);
        const brushPipeline = try graphics.ComputePipeline.init("shaders/brush.comp", allocator);
        const simPipeline = try graphics.ComputePipeline.init("shaders/sim.comp", allocator);

        var uniforms = graphics.UniformBuffer(ApplicationState).init();
        uniforms.bind(drawPipeline.program, 3, "globals");
        uniforms.bind(brushPipeline.program, 3, "globals");
        uniforms.bind(simPipeline.program, 3, "globals");

        var smaterials = graphics.UniformBuffer(@TypeOf(materials.MATERIAL_LIST)).init();
        smaterials.update(materials.MATERIAL_LIST);
        smaterials.bind(drawPipeline.program, 4, "materials");
        smaterials.bind(brushPipeline.program, 4, "materials");
        smaterials.bind(simPipeline.program, 4, "materials");

        return Application{ .window = window.?, .renderFramebuffer = renderFramebuffer, .renderTexture = renderTexture, .drawPipeline = drawPipeline, .brushPipeline = brushPipeline, .simPipeline = simPipeline, .worldTexture = worldTexture, .globals = uniforms, .materials = smaterials };
    }

    /// Called when the window is resized.
    pub fn on_resize(win: glfw.Window, width: u32, height: u32) void {
        var app = win.getUserPointer(Application).?;

        // recreate the render texture and framebuffer
        app.renderFramebuffer.deinit();
        app.renderTexture.deinit();
        app.worldTexture.deinit();
        app.worldTexture = graphics.Texture.init(@intCast(width), @intCast(height), graphics.gl.RGBA8I, 2);
        app.renderTexture = graphics.Texture.init(@intCast(width), @intCast(height), graphics.gl.RGBA8, 1);
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
            .b => {
                app.brushType = switch (app.brushType) {
                    .circle => .square,
                    .square => .hline,
                    .hline => .circle,
                };
                std.log.debug("Brush type is now {}", .{app.brushType});
            },
            .space => {
                app.simState = switch (app.simState) {
                    .running => .paused,
                    .paused => .running,
                    else => .paused,
                };
                std.log.debug("Simulation state is now {}", .{app.simState});
            },
            .p => {
                app.simState = .step;
                std.log.debug("Stepping simulation", .{});
            },
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
            .brushType = app.brushType,
            .material = app.currentMaterial,
            .inputState = inputState,
            .time = @floatCast(glfw.getTime()),
            .simRunning = @intFromBool(app.simState != .paused),
        });
    }

    // Draw the world to the render texture and then blit it to the screen.
    pub fn draw(app: *@This()) void {
        var size = app.window.getSize();
        const workgroupSize = app.drawPipeline.getWorkgroupSize();
        const workgroupCount = [_]u32{ @intFromFloat(@ceil(@as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(workgroupSize[0])))), @intFromFloat(@ceil(@as(f32, @floatFromInt(size.height)) / @as(f32, @floatFromInt(workgroupSize[1])))), workgroupSize[2] };
        const nextFrameWorldImageIndex = 1 - app.currentWorldImageIndex;

        // brush pipeline
        // apply the brush to the current world texture
        app.brushPipeline.use();
        app.worldTexture.bind_image_layer(0, @intCast(app.currentWorldImageIndex), graphics.gl.WRITE_ONLY);
        app.brushPipeline.dispatch(workgroupCount[0], workgroupCount[1], workgroupCount[2]);

        // sim pipeline
        // runs the per-pixel simulation
        app.simPipeline.use();
        app.worldTexture.bind_image_layer(0, @intCast(app.currentWorldImageIndex), graphics.gl.WRITE_ONLY);
        app.worldTexture.bind_image_layer(1, @intCast(nextFrameWorldImageIndex), graphics.gl.READ_ONLY);
        app.simPipeline.dispatch(@intCast(size.width), @intCast(size.height), 1);

        // draw pipeline
        // draws the world to the render texture
        app.drawPipeline.use();
        app.renderTexture.bind_image(0, graphics.gl.WRITE_ONLY);
        app.worldTexture.bind_image_layer(1, @intCast(app.currentWorldImageIndex), graphics.gl.READ_ONLY);
        app.drawPipeline.dispatch(workgroupCount[0], workgroupCount[1], workgroupCount[2]);
        app.renderFramebuffer.blit(0, @intCast(size.width), @intCast(size.height));

        app.currentWorldImageIndex = nextFrameWorldImageIndex;
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
            if (app.simState == .step)
                app.simState = .paused;
            app.window.swapBuffers();
        }
    }
};
