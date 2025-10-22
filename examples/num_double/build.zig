const std = @import("std");
const phpzx = @import("phpzx");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const phpzx_dep = b.dependency("phpzx", .{
        .target = target,
        .optimize = optimize,
    });

    const phpzx_mod = phpzx_dep.module("phpzx");

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_mod.addImport("phpzx", phpzx_mod);

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "myext",
        .root_module = lib_mod,
    });

    lib.linker_allow_shlib_undefined = true;

    phpzx.setupPhpConfig(lib, b) catch @panic("Failed to setup PHP configuration");

    b.installArtifact(lib);
}
