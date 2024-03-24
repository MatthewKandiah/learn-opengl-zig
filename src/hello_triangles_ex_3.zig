const std = @import("std");
const util = @import("util.zig");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const vertices1 = [_]f32{
    -0.75, 0.5, 0.0, // triangle 1 top left
    -0.25, 0.5, 0.0, // triangle 1 top right
    -0.5, -0.5, 0.0, // triangle 1 bottom
};
const vertices2 = [_]f32{
    0.25, -0.5, 0.0, // triangle 2 bottom left
    0.75, -0.5, 0.0, // triangle 2 bottom right
    0.5, 0.5, 0.0, // triangle 2 top
};

const vertex_shader_source: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const red_fragment_shader_source: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\  FragColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
    \\}
;

const yellow_fragment_shader_source: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\  FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);
    \\}
;

pub fn main() !void {
    // laziness, going to just define a single `success` flag and a single `infoLog` text buffer for each thing that could fail
    var success: i32 = 0;
    var infoLog: [512]u8 = undefined;

    const window = try util.init("Hello Triangles - Exercise 1");
    defer {
        util.deinit();
    }

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source, null);
    c.glCompileShader(vertex_shader);
    c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vertex_shader, 512, null, &infoLog);
        std.debug.panic("Vertex shader compilation failed\n{s}", .{infoLog});
    }

    const red_fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(red_fragment_shader, 1, &red_fragment_shader_source, null);
    c.glCompileShader(red_fragment_shader);
    c.glGetShaderiv(red_fragment_shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(red_fragment_shader, 512, null, &infoLog);
        std.debug.panic("Fragment shader compilation failed\n{s}", .{infoLog});
    }

    const yellow_fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(yellow_fragment_shader, 1, &yellow_fragment_shader_source, null);
    c.glCompileShader(yellow_fragment_shader);
    c.glGetShaderiv(yellow_fragment_shader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(yellow_fragment_shader, 512, null, &infoLog);
        std.debug.panic("Fragment shader compilation failed\n{s}", .{infoLog});
    }

    const red_shader_program = c.glCreateProgram();
    c.glAttachShader(red_shader_program, vertex_shader);
    c.glAttachShader(red_shader_program, red_fragment_shader);
    c.glLinkProgram(red_shader_program);
    c.glGetProgramiv(red_shader_program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        c.glGetProgramInfoLog(red_shader_program, 512, null, &infoLog);
        std.debug.panic("Red shader program linking failed\n{s}", .{infoLog});
    }

    const yellow_shader_program = c.glCreateProgram();
    c.glAttachShader(yellow_shader_program, vertex_shader);
    c.glAttachShader(yellow_shader_program, yellow_fragment_shader);
    c.glLinkProgram(yellow_shader_program);
    c.glGetProgramiv(yellow_shader_program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        c.glGetProgramInfoLog(yellow_shader_program, 512, null, &infoLog);
        std.debug.panic("Yellow shader program linking failed\n{s}", .{infoLog});
    }

    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(red_fragment_shader);
    c.glDeleteShader(yellow_fragment_shader);

    var vao_left: u32 = 0;
    c.glGenVertexArrays(1, &vao_left);
    var vbo_left: u32 = 0;
    c.glGenBuffers(1, &vbo_left);

    c.glBindVertexArray(vao_left);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo_left);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices1)), &vertices1, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    var vao_right: u32 = 0;
    c.glGenVertexArrays(1, &vao_right);
    var vbo_right: u32 = 0;
    c.glGenBuffers(1, &vbo_right);

    c.glBindVertexArray(vao_right);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo_right);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices2)), &vertices2, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    // // wireframe
    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
        c.glClearColor(0.8, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(red_shader_program);
        c.glBindVertexArray(vao_left);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glUseProgram(yellow_shader_program);
        c.glBindVertexArray(vao_right);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}
