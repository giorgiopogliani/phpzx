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

    const exe = b.addExecutable(.{
        .name = "php-sapi",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("phpzx", phpzx_mod);

    // Get PHP includes, libs, and ldflags via php-config
    const php_includes_raw = try runCommand(b.allocator, &.{ "php-config", "--includes" });
    const php_libs = try runCommand(b.allocator, &.{ "php-config", "--libs" });
    const php_ldflags = try runCommand(b.allocator, &.{ "php-config", "--ldflags" });

    // Add PHP include paths
    var includes_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_includes_raw, " \n\r\t"), ' ');
    while (includes_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            exe.addIncludePath(.{ .cwd_relative = flag[2..] });
        }
    }

    // Add PHP library paths and libraries
    var libs_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_libs, " \n\r\t"), ' ');
    while (libs_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-L")) {
            exe.addLibraryPath(.{ .cwd_relative = flag[2..] });
        } else if (std.mem.startsWith(u8, flag, "-l")) {
            exe.linkSystemLibrary(flag[2..]);
        }
    }

    // Add PHP linker flags
    var ldflags_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_ldflags, " \n\r\t"), ' ');
    while (ldflags_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-L")) {
            exe.addLibraryPath(.{ .cwd_relative = flag[2..] });
        }
    }

    // Link PHP embed library
    exe.linkSystemLibrary("php");
    exe.linkLibC();

    b.installArtifact(exe);

    // Create a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the SAPI");
    run_step.dependOn(&run_cmd.step);
}
