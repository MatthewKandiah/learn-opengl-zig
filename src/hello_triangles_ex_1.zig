const std = @import("std");
const util = @import("util.zig");

pub fn main() !void {
    const window = try util.init("Hello Triangles - Exercise 1");
    _ = window;
    defer util.deinit();
}
