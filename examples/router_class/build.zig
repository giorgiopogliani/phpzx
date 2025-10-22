const std = @import("std");
const phpzx = @import("phpzx");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = phpzx.configureExtension(b, .{
      .name = "myext",
      .module = lib_mod,
    });

    b.installArtifact(lib);
}
