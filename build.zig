const std = @import("std");

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) []u8 {
    var child = std.process.Child.init(args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;

    child.spawn() catch @panic("Failed to spawn process");

    const stdout = child.stdout.?.reader().readAllAlloc(allocator, 10 * 1024) catch @panic("Failed to read stdout");

    const term = child.wait() catch @panic("Failed to wait for process");
    if (term.Exited != 0) @panic("Command failed");

    return stdout;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("phpzx", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addSharedLibrary(.{
        .name = "phpzx",
        .root_module = lib_mod,
        .optimize = optimize,
    });

    lib.linker_allow_shlib_undefined = true;

    const php_includes_raw = runCommand(b.allocator, &.{ "php-config", "--includes" });

    lib.addCSourceFiles(.{ .files = &[_][]const u8{
        "src/module.c",
    }, .flags = &[_][]const u8{
        php_includes_raw,
    } });

    // Add PHP include paths
    var includes_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_includes_raw, " \n\r\t"), ' ');
    while (includes_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            lib.addIncludePath(.{ .cwd_relative = flag[2..] });
        }
    }

    b.installArtifact(lib);
}
