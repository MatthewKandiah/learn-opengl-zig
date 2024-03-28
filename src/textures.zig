const std = @import("std");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

// I get build errors if this is included in the main cImport block
// Splitting out a separate cImport block seems to fix it, would be interesting to bottom out why!
const stb = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", {});
    @cInclude("stb_image.h");
});

const double_triangle_vertices = [_]f32{
    0.5,  0.5,  0.0,
    0.5,  -0.5, 0.0,
    -0.5, -0.5, 0.0,
    -0.5, 0.5,  0.0,
};

const double_triangle_indices = [_]c_uint{
    0, 1, 3,
    1, 2, 3,
};

const vertex_shader_source: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment_shader_source: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

pub fn main() !void {
    const window = try util.init("Hello Triangles");
    defer {
        util.deinit();
    }

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source, null);
    c.glCompileShader(vertex_shader);
    var vertex_shader_compilation_succeeded: c_int = undefined;
    c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &vertex_shader_compilation_succeeded);
    if (vertex_shader_compilation_succeeded == 0) {
        var info: [512]u8 = undefined;
        c.glGetShaderInfoLog(vertex_shader, 512, null, &info);
        std.debug.panic("Vertex shader compilation failed: {s}", .{info});
    }

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_source, null);
    c.glCompileShader(fragment_shader);
    var fragment_shader_compilation_succeeded: c_int = undefined;
    c.glGetShaderiv(fragment_shader, c.GL_COMPILE_STATUS, &fragment_shader_compilation_succeeded);
    if (fragment_shader_compilation_succeeded == 0) {
        var info: [512]u8 = undefined;
        c.glGetShaderInfoLog(fragment_shader, 512, null, &info);
        std.debug.panic("Fragment shader compilation failed: {s}", .{info});
    }

    const shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);
    var shader_program_linkage_succeeded: c_int = undefined;
    c.glGetProgramiv(shader_program, c.GL_LINK_STATUS, &shader_program_linkage_succeeded);
    if (shader_program_linkage_succeeded == 0) {
        var info: [512]u8 = undefined;
        c.glGetProgramInfoLog(shader_program, 512, null, &info);
        std.debug.panic("Shader program linkage failed: {s}", .{info});
    }
    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    var vao2: c_uint = 0;
    c.glGenVertexArrays(1, &vao2);
    var vbo2: c_uint = 0;
    c.glGenBuffers(1, &vbo2);
    var ebo: c_uint = 0;
    c.glGenBuffers(1, &ebo);
    c.glBindVertexArray(vao2);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo2);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(double_triangle_vertices)), &double_triangle_vertices, c.GL_STATIC_DRAW);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(double_triangle_indices)), &double_triangle_indices, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glUseProgram(shader_program);

        c.glBindVertexArray(vao2);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @ptrFromInt(0));

        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}
