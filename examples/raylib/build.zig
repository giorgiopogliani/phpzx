const std = @import("std");
const phpzx = @import("phpzx");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "raylib", .module = raylib_dep.module("raylib") },
        },
    });

    const lib = phpzx.configureExtension(b, .{
        .name = "autoport",
        .module = lib_mod,
    });

    lib.linkLibrary(raylib_dep.artifact("raylib"));

    b.installArtifact(lib);
}
