const std = @import("std");
const util = @import("util.zig");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    const window = try util.init("Hello Triangles - Exercise 1");
    defer {
        util.deinit();
    }

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
        c.glClearColor(0.8, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, 1);
    }
}
