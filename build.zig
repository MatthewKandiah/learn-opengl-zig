const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const outputs = [_]Output{
        .{ .name = "hello_triangles", .src = "src/hello_triangles.zig", .description = "Hello OpenGL Triangles", .target = target, .optimize = optimize },
        .{ .name = "hello_triangles_ex_1", .src = "src/hello_triangles_ex_1.zig", .description = "2 triangles using more vertices", .target = target, .optimize = optimize },
        .{ .name = "hello_triangles_ex_2", .src = "src/hello_triangles_ex_2.zig", .description = "2 triangle using separate VAOs and BAOs", .target = target, .optimize = optimize },
        .{ .name = "hello_triangles_ex_3", .src = "src/hello_triangles_ex_3.zig", .description = "2 triangles using separate fragment shaders to render in 2 different colours", .target = target, .optimize = optimize },
        .{ .name = "shaders", .src = "src/shaders.zig", .description = "Shaders beyond the bare basics", .target = target, .optimize = optimize },
        .{ .name = "shaders_ex_1", .src = "src/shaders_ex_1.zig", .description = "Adjust vertical shader so rectangle is upside down", .target = target, .optimize = optimize },
        .{ .name = "shaders_ex_2", .src = "src/shaders_ex_2.zig", .description = "Use uniform to shift triangle to the right", .target = target, .optimize = optimize },
        .{ .name = "shaders_ex_3", .src = "src/shaders_ex_3.zig", .description = "Pass vertex position to fragment shader and set fragment colour to vertex position", .target = target, .optimize = optimize },
        .{ .name = "textures", .src = "src/textures.zig", .description = "Introducing textures", .target = target, .optimize = optimize },
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
        const stb_image_source_file = .{ .file = std.build.LazyPath{ .path = "deps/src/stb_image_impl.c" }, .flags = &[_][]u8{} };
        exe.addCSourceFile(stb_image_source_file);

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
