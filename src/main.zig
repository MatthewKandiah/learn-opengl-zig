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

    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    _ = c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    // to build on mac, you may need to uncomment this line
    // _ = c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    var window = c.glfwCreateWindow(800, 600, "LearnOpenGL", null, null);
    if (window == null) {
        std.debug.panic("Failed to create GLFW window.\n", .{});
    }

    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        std.debug.panic("Failed to initialize GLAD\n", .{});
    }

    c.glViewport(0, 0, 800, 600);

    const resizeCallback = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    _ = resizeCallback;

    runRenderLoop(window);
}

fn runRenderLoop(window: ?*c.GLFWwindow) void {
    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
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
