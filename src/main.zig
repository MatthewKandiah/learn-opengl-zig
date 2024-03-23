const std = @import("std");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    const init_ok = c.glfwInit();
    if (init_ok == 0) {
        std.debug.panic("Failed to initialise GLFW\n", .{});
    }

    defer {
        c.glfwTerminate();
    }

    setWindowHints();

    var window = c.glfwCreateWindow(800, 600, "LearnOpenGL", null, null);
    if (window == null) {
        std.debug.panic("Failed to create GLFW window.\n", .{});
    }

    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        std.debug.panic("Failed to initialize GLAD\n", .{});
    }

    c.glViewport(0, 0, 800, 600);

    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source, null);
    c.glCompileShader(vertex_shader);
    var vertex_shader_compilation_succeeded: c_int = undefined;
    c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &vertex_shader_compilation_succeeded);
    if (vertex_shader_compilation_succeeded == 0) {
        var shader_compilation_error_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(vertex_shader, 512, null, &shader_compilation_error_log);
        std.debug.panic("Vertex shader compilation failed\n{s}", .{shader_compilation_error_log});
    }

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_shader_source, null);
    c.glCompileShader(fragment_shader);
    var fragment_shader_compilation_succeeded: c_int = undefined;
    c.glGetShaderiv(fragment_shader, c.GL_COMPILE_STATUS, &fragment_shader_compilation_succeeded);
    if (fragment_shader_compilation_succeeded == 0) {
        var shader_compilation_error_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(fragment_shader, 512, null, &shader_compilation_error_log);
        std.debug.panic("Fragment shader compilation failed\n{s}", .{shader_compilation_error_log});
    }

    var shader_program: c_uint = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);
    var shader_program_linking_succeeded: c_int = undefined;
    c.glGetProgramiv(shader_program, c.GL_LINK_STATUS, &shader_program_linking_succeeded);
    if (shader_program_linking_succeeded == 0) {
        var shader_linking_error_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader_program, 512, null, &shader_linking_error_log);
        std.debug.panic("Shader program linking failed\n{s}", .{shader_linking_error_log});
    }
    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    const vertices = [9]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glBindVertexArray(vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 0, @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);

        c.glClearColor(0.3, 0.0, 0.6, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shader_program);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

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

fn setWindowHints() void {
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    _ = c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    // to build on mac, you may need to uncomment this line
    // _ = c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
}

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}
