const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const InitialisationError = error{
    GLFWInitialisationFailed,
    GLADInitialisationFailed,
    WindowInitialisationFailed,
};

pub fn init(title: [:0]const u8) InitialisationError!?*c.GLFWwindow {
    const init_ok = c.glfwInit();
    if (init_ok == 0) {
        return InitialisationError.GLFWInitialisationFailed;
    }

    return makeHookedUpWindow(title);
}

fn makeHookedUpWindow(title: [:0]const u8) !*c.GLFWwindow {
    const window = try makeWindow(title);
    c.glfwMakeContextCurrent(window);
    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        return InitialisationError.GLADInitialisationFailed;
    }
    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    return window;
}

fn makeWindow(title: [:0]const u8) !*c.GLFWwindow {
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    _ = c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    _ = c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    // to build on mac, you may need to uncomment this line
    // _ = c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    var window = c.glfwCreateWindow(800, 600, title, null, null);
    if (window) |w| {
        return w;
    } else {
        return InitialisationError.WindowInitialisationFailed;
    }
}

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}

pub fn deinit() void {
    c.glfwTerminate();
}
