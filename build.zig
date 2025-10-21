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

    // const test_step = b.addTest(.{
    //     .name = "test",
    //     .root_module = lib_mod,
    // });

    // test_step.addCSourceFiles(.{
    //   .files = &[_][]const u8{
    //       // "src/_module.c",
    //   },
    //   .flags = &[_][]const u8{
    //       "-DTARGET_EXTENSION",
    //       php_includes,
    //   },
    // });
    const test_step = b.step("test", "Run unit");

    const tests = [_]*std.Build.Step.Compile{
        b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/module.zig"),
                .target = target,
                .optimize = optimize,
            }),
        }),
        b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/root.zig"),
                .target = target,
                .optimize = optimize,
            }),
        }),
    };

    for (tests) |test_item| {
        test_item.linkLibC();

        var iter = std.mem.tokenizeScalar(u8, php_includes, ' ');
        while (iter.next()) |include| {
            if (std.mem.startsWith(u8, include, "-I")) {
                const path = std.mem.trim(u8, include[2..], "\n\r");
                test_item.root_module.addIncludePath(.{ .cwd_relative = path });
            }
        }
        const run_tests = b.addRunArtifact(test_item);
        test_step.dependOn(&run_tests.step);
    }
}

fn runCommand(allocator: std.mem.Allocator, args: []const []const u8) ![]u8 {
    var child = std.process.Child.init(args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;

    child.spawn() catch @panic("Failed to spawn process");

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 10 * 1024);
    const term = child.wait() catch @panic("Failed to wait for process");

    if (term.Exited != 0) @panic("Command failed");

    return stdout;
}
