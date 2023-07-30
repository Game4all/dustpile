pub const gl = @import("gl45.zig");
const glfw = @import("glfw");
const std = @import("std");

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

// read a whole file into a string.
fn readToEnd(file: []const u8, alloc: std.mem.Allocator) ![:0]const u8 {
    const fileSt = try std.fs.cwd().openFile(file, std.fs.File.OpenFlags{ .mode = .read_only });
    const sourceStat = try fileSt.stat();
    const source = try std.fs.File.readToEndAllocOptions(fileSt, alloc, @as(usize, 2 * sourceStat.size), @as(usize, sourceStat.size), 1, 0);
    return source;
}

// read a whole file into a string, and replace all #include statements with the contents of the included file.
pub fn readGLSLSource(filepath: []const u8, alloc: std.mem.Allocator) ![:0]const u8 {
    const file = try std.fs.cwd().openFile(filepath, std.fs.File.OpenFlags{ .mode = .read_only });
    defer file.close();

    var finalSource = std.ArrayList(u8).init(alloc);
    var sourceWriter = finalSource.writer();

    const fileReader = file.reader();
    var buffered_line: [1024]u8 = undefined;
    while (try fileReader.readUntilDelimiterOrEof(&buffered_line, '\r')) |line| {
        if (std.mem.indexOf(u8, line, "#include")) |index| {
            var fileName = line[index + 9 ..];
            const depContents = readToEnd(fileName, alloc) catch |err| {
                std.log.err("Failed to read GLSL file {s}: {}", .{ fileName, err });
                continue;
            };
            try sourceWriter.writeAll(depContents);
            alloc.free(depContents);
        } else {
            try sourceWriter.writeAll(line);
        }
    }
    return try finalSource.toOwnedSliceSentinel(0);
}

/// Loads OpenGL functions for the given window.
pub fn loadOpenGL(window: glfw.Window) !void {
    glfw.makeContextCurrent(window);
    var glproc: glfw.GLProc = undefined;
    try gl.load(glproc, glGetProcAddress);
}

// Returns a compiled shader handle of the given type.
pub fn getShader(file: []const u8, shader_kind: gl.GLenum, alloc: std.mem.Allocator) !gl.GLuint {
    const source = try readGLSLSource(file, alloc);
    std.log.info("Compiling shader: {s}", .{file});

    const handle = gl.createShader(shader_kind);
    gl.shaderSource(handle, 1, @ptrCast(&source), null);
    gl.compileShader(handle);
    var info_log: [1024]u8 = undefined;
    var info_log_len: gl.GLsizei = undefined;
    gl.getShaderInfoLog(handle, 1024, &info_log_len, &info_log);
    if (info_log_len != 0) {
        std.log.info("Error while compiling shader {s} : {s}", .{ file, info_log[0..@intCast(info_log_len)] });
        return error.ShaderCompilationError;
    }
    alloc.free(source);
    return handle;
}

// Returns a linked shader program from the given shaders.
pub fn getShaderProgram(shadersHandles: anytype) !gl.GLuint {
    const program = gl.createProgram();
    inline for (shadersHandles) |handle| {
        gl.attachShader(program, handle);
    }
    var link_status: gl.GLint = undefined;
    var info_log: [1024]u8 = undefined;
    var info_log_len: gl.GLsizei = undefined;
    gl.linkProgram(program);
    gl.getProgramiv(program, gl.LINK_STATUS, &link_status);
    gl.getProgramInfoLog(program, 1024, &info_log_len, &info_log);
    if (link_status == gl.FALSE) {
        std.log.info("Failed to link shader program: {s}", .{info_log[0..@intCast(info_log_len)]});
        gl.deleteProgram(program);
        return error.ProgramLinkError;
    } else {
        std.log.info("Shader program linked OK", .{});
        return program;
    }
}

/// Represents a compute pipeline.
pub const ComputePipeline = struct {
    program: gl.GLuint,

    pub fn init(file: []const u8, alloc: std.mem.Allocator) !@This() {
        const shader = try getShader(file, gl.COMPUTE_SHADER, alloc);
        const compute_prog = try getShaderProgram(.{shader});

        return .{ .program = compute_prog };
    }

    /// Dispatches the compute shader for execution with the given dimensions.
    pub fn dispatch(this: *@This(), x: gl.GLuint, y: gl.GLuint, z: gl.GLuint) void {
        _ = this;
        gl.dispatchCompute(x, y, z);
        gl.memoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT);
    }

    /// Binds this program for use.
    /// You should call and set uniforms before calling this.
    pub fn use(this: *@This()) void {
        gl.useProgram(this.program);
    }

    pub fn deinit(this: *@This()) void {
        gl.deleteProgram(this.program);
    }
};

/// A texture that can be used as a storage image in compute shaders.
pub const Texture = struct {
    texture: gl.GLuint,
    w: u32,
    h: u32,
    format: gl.GLenum,

    pub fn init(width: u32, height: u32, format: gl.GLenum) @This() {
        var texture: gl.GLuint = undefined;
        gl.createTextures(gl.TEXTURE_2D, 1, &texture);
        gl.textureStorage2D(texture, 1, format, @intCast(width), @intCast(height));

        return .{ .texture = texture, .w = width, .h = height, .format = format };
    }

    /// Bind the texture to the given binding index for rendering.
    pub fn bind_texture(this: *@This(), bindingIndex: gl.GLuint) void {
        gl.bindTextureUnit(bindingIndex, this.texture);
    }

    /// Bind the texture as an to the given binding index for compute.
    pub fn bind_image(this: *@This(), bindingIndex: gl.GLuint, usage: gl.GLenum) void {
        gl.bindImageTexture(bindingIndex, this.texture, 0, gl.FALSE, 0, usage, this.format);
    }

    /// Clear the texture to the given color.
    pub fn clear(this: *@This(), data: []const u8) void {
        gl.clearTexImage(this.texture, 0, this.format, gl.UNSIGNED_BYTE, @ptrCast(data));
    }

    pub fn set_data(this: *@This(), data_format: gl.GLenum, data: []const u8) void {
        gl.textureSubImage2D(this.texture, 0, 0, 0, @intCast(this.w), @intCast(this.h), this.format, data_format, data);
    }

    pub fn deinit(this: *@This()) void {
        gl.deleteTextures(1, &this.texture);
    }
};

/// A framebuffer that can be used as a render target.
pub const Framebuffer = struct {
    framebuffer: gl.GLuint,

    pub fn init(storage: *const Texture) @This() {
        var framebuffer: gl.GLuint = undefined;
        gl.createFramebuffers(1, &framebuffer);
        gl.namedFramebufferTexture(framebuffer, gl.COLOR_ATTACHMENT0, storage.*.texture, 0);
        return .{ .framebuffer = framebuffer };
    }

    pub fn deinit(this: *@This()) void {
        gl.deleteFramebuffers(1, &this.framebuffer);
    }

    pub fn blit(this: *@This(), dest: gl.GLuint, width: gl.GLsizei, height: gl.GLsizei) void {
        gl.blitNamedFramebuffer(this.framebuffer, dest, 0, 0, width, height, 0, 0, width, height, gl.COLOR_BUFFER_BIT, gl.NEAREST);
    }
};

/// A bindable uniform buffer object.
/// Provides a type-safe interface to a uniform buffer of underlying type `uniformStructType`.
pub fn UniformBuffer(comptime uniformStructType: type) type {
    return struct {
        buffer: gl.GLuint,

        pub fn init() @This() {
            var buffer: gl.GLuint = undefined;
            gl.createBuffers(1, &buffer);
            return .{ .buffer = buffer };
        }

        /// Bind the uniform buffer to the given binding index.
        pub fn bind(this: *@This(), program: gl.GLuint, bindingIndex: u32, name: [:0]const u8) void {
            var blockIndex = gl.getUniformBlockIndex(program, name);
            gl.uniformBlockBinding(program, blockIndex, @intCast(bindingIndex));
            gl.bindBufferBase(gl.UNIFORM_BUFFER, bindingIndex, this.buffer);
        }

        // Update the buffer with the given data.
        // This should be called once per frame.
        pub fn update(this: *@This(), data: uniformStructType) void {
            gl.namedBufferData(this.buffer, @intCast(@sizeOf(uniformStructType)), &data, gl.STREAM_READ);
        }

        pub fn deinit(this: *@This()) void {
            gl.deleteBuffers(1, &this.buffer);
        }
    };
}
