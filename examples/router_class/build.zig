const std = @import("std");

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) ![]u8 {
    var child = std.process.Child.init(args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;
    child.spawn() catch @panic("Failed to spawn process");

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024);
    const term = child.wait() catch @panic("Failed to wait for process");

    switch (term) {
        .Exited => |code| if (code != 0) @panic("Command failed"),
        else => @panic("Process did not exit normally"),
    }

    return stdout;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const phpzx = b.dependency("phpzx", .{
        .target = target,
        .optimize = optimize,
    });

    const phpzx_mod = phpzx.module("phpzx");

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

    // Get PHP includes, libs, and ldflags via php-config
    const php_includes_raw = try runCommand(b.allocator, &.{ "php-config", "--includes" });

    // Add C source files with compilation flags
    // lib.addCSourceFiles(.{
    //     .files = &[_][]const u8{
    //         // "src/_module.c",
    //     },
    //     .flags = &[_][]const u8{
    //         "-DTARGET_EXTENSION",
    //         php_includes_raw,
    //     },
    // });

    // Add PHP include paths
    var includes_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_includes_raw, " \n\r\t"), ' ');
    while (includes_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            lib.addIncludePath(.{ .cwd_relative = flag[2..] });
        }
    }

    b.installArtifact(lib);
}
