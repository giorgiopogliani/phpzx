const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("phpzx", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "phpzx",
        .root_module = lib_mod,
    });

    const php_includes = try runCommand(b.allocator, &.{ "php-config", "--includes" });
    var it = std.mem.tokenizeScalar(u8, php_includes, ' ');
    while (it.next()) |include| {
        if (std.mem.startsWith(u8, include, "-I")) {
            const path = std.mem.trim(u8, include[2..], "\n\r");
            lib.addIncludePath(.{ .cwd_relative = path });
        }
    }

    lib.linker_allow_shlib_undefined = true;

    b.installArtifact(lib);

    const test_step = b.step("test", "Run unit");

    const tests = [_]*std.Build.Step.Compile{b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    })};

    for (tests) |test_item| {
        test_item.linkLibC();

        var it2 = std.mem.tokenizeScalar(u8, php_includes, ' ');
        while (it2.next()) |include| {
            if (std.mem.startsWith(u8, include, "-I")) {
                const path = std.mem.trim(u8, include[2..], "\n\r");
                test_item.addIncludePath(.{ .cwd_relative = path });
            }
        }

        test_item.linker_allow_shlib_undefined = true;

        const run_tests = b.addRunArtifact(test_item);
        test_step.dependOn(&run_tests.step);
    }
}

pub fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) ![]u8 {
    var child = std.process.Child.init(args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;

    child.spawn() catch @panic("Failed to spawn process");

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024);
    const term = child.wait() catch @panic("Failed to wait for process");

    if (term.Exited != 0) @panic("Command failed");

    return stdout;
}

pub fn setupPhpConfig(lib: *std.Build.Step.Compile, b: *std.Build) !void {
    // Get PHP includes, libs, and ldflags via php-config
    const php_includes_raw = try runCommand(b.allocator, &.{ "php-config", "--includes" });

    // Add PHP include paths
    var includes_iter = std.mem.tokenizeScalar(u8, std.mem.trim(u8, php_includes_raw, " \n\r\t"), ' ');
    while (includes_iter.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "-I")) {
            lib.addIncludePath(.{ .cwd_relative = flag[2..] });
        }
    }
}

pub fn configureExtension(b: *std.Build, options: struct { name: []const u8, module: *std.Build.Module }) *std.Build.Step.Compile {
    const phpzx_dep = b.dependency("phpzx", .{});

    const phpzx_mod = phpzx_dep.module("phpzx");

    options.module.addImport("phpzx", phpzx_mod);

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = options.name,
        .root_module = options.module,
    });

    lib.linker_allow_shlib_undefined = true;

    setupPhpConfig(lib, b) catch @panic("Failed to setup PHP configuration");

    return lib;
}
