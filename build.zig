const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const outputs = [_]Output{
        .{ .name = "hello_triangles", .src = "src/hello_triangles.zig", .description = "Hello OpenGL Triangles", .target = target, .optimize = optimize },
        .{ .name = "hello_triangles_ex_1", .src = "src/hello_triangles_ex_1.zig", .description = "2 triangles using more vertices", .target = target, .optimize = optimize },
        .{ .name = "hello_triangles_ex_2", .src = "src/hello_triangles_ex_2.zig", .description = "2 triangle using separate VAOs and BAOs", .target = target, .optimize = optimize },
    };

    for (outputs) |output| {
        output.build(b);
    }
}

const Output = struct {
    name: []const u8,
    src: []const u8,
    description: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,

    const Self = @This();

    fn build(self: Self, b: *std.Build) void {
        const exe = b.addExecutable(.{
            .name = self.name,
            .root_source_file = .{ .path = self.src },
            .target = self.target,
            .optimize = self.optimize,
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

        const run_step = b.step(self.name, self.description);
        run_step.dependOn(&run_cmd.step);
    }
};
