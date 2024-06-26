const std = @import("std");
const util = @import("util.zig");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

// I get build errors if this is included in the main cImport block
// Splitting out a separate cImport block seems to fix it, would be interesting to bottom out why!
const stb = @cImport({
    @cInclude("stb_image.h");
});

const vertex_shader_source: [*c]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec2 aTexCoord;
    \\
    \\out vec2 TexCoord;
    \\
    \\void main()
    \\{
    \\  gl_Position = vec4(aPos, 1.0);
    \\  TexCoord = aTexCoord;
    \\}
;

const fragment_shader_source: [*c]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\in vec2 TexCoord;
    \\
    \\uniform sampler2D texture1;
    \\uniform sampler2D texture2;
    \\
    \\void main()
    \\{
    \\  FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
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

    const vertices = [_]f32{
        0.5,  0.5,  0.0, 2.0, 2.0,
        0.5,  -0.5, 0.0, 2.0, 0.0,
        -0.5, -0.5, 0.0, 0.0, 0.0,
        -0.5, 0.5,  0.0, 0.0, 2.0,
    };

    const indices = [_]c_uint{
        0, 1, 3,
        1, 2, 3,
    };

    var vao: c_uint = 0;
    c.glGenVertexArrays(1, &vao);
    var vbo: c_uint = 0;
    c.glGenBuffers(1, &vbo);
    var ebo: c_uint = 0;
    c.glGenBuffers(1, &ebo);

    c.glBindVertexArray(vao);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);
    // texture coordinates attribute
    c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // load and create texture
    var texture1: c_uint = 0;
    c.glGenTextures(1, &texture1);
    c.glBindTexture(c.GL_TEXTURE_2D, texture1);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    var width: c_int = undefined;
    var height: c_int = undefined;
    var nrChannels: c_int = undefined;
    var data: [*]u8 = undefined;

    stb.stbi_set_flip_vertically_on_load(1);

    data = stb.stbi_load("src/textures/container.jpg", &width, &height, &nrChannels, 0);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    stb.stbi_image_free(data);

    c.glUseProgram(shader_program);
    c.glUniform1i(c.glGetUniformLocation(shader_program, "texture1"), 0);

    var texture2: c_uint = 0;
    c.glGenTextures(1, &texture2);
    c.glBindTexture(c.GL_TEXTURE_2D, texture2);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_MIRRORED_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_MIRRORED_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    data = stb.stbi_load("src/textures/awesomeface.png", &width, &height, &nrChannels, 0);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    stb.stbi_image_free(data);

    c.glUseProgram(shader_program);
    c.glUniform1i(c.glGetUniformLocation(shader_program, "texture2"), 1);

    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        c.glUseProgram(shader_program);
        c.glBindVertexArray(vao);
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
