const std = @import("std");

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

    exe.linkLibrary(glfw.artifact("mach-glfw"));
    exe.addModule("glfw", glfw.module("mach-glfw"));
    @import("glfw").addPaths(exe);

    exe.linkLibrary(b.dependency("vulkan_headers", .{
        .target = target,
        .optimize = optimize,
    }).artifact("vulkan-headers"));

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
