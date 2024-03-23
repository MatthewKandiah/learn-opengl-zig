const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "learn-opengl-zig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Includes
    exe.addIncludePath(.{ .path = "deps/include" });

    // Sources
    const glad_source_file = .{ .file = std.build.LazyPath{ .path = "deps/src/glad.c" }, .flags = &[_][]u8{} };
    exe.addCSourceFile(glad_source_file);

    // Libraries
    exe.linkLibC();
    exe.linkSystemLibrary("glfw3");

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
