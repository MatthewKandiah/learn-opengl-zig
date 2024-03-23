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

    const vertices = [9]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
    var vbo: c_uint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    var vertex_shader: c_uint = undefined;
    vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_shader_source, null);
    c.glCompileShader(vertex_shader);
    var shader_compilation_succeeded: c_int = undefined;
    c.glGetShaderiv(vertex_shader, c.GL_COMPILE_STATUS, &shader_compilation_succeeded);
    if (shader_compilation_succeeded == 0) {
        var shader_compilation_error_log: [512]u8 = undefined;
        c.glGetShaderInfoLog(vertex_shader, 512, null, &shader_compilation_error_log);
        std.debug.panic("Vertex shader compilation failed\n{s}", .{shader_compilation_error_log});
    }

    runRenderLoop(window);
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

fn setWindowHints() void {
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    _ = c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    // to build on mac, you may need to uncomment this line
    // _ = c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
}

fn runRenderLoop(window: ?*c.GLFWwindow) void {
    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);

        c.glClearColor(0.3, 0.0, 0.6, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
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
