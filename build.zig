const std = @import("std");
const mach_glfw = @import("mach_glfw");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "dustpile",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    //glfw dependency
    const glfw = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("glfw", glfw.module("mach-glfw"));
    mach_glfw.addPaths(exe);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
