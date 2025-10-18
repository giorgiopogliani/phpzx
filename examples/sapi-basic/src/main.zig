const std = @import("std");
const php = @import("phpzx").c;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <php-script.php>\n", .{args[0]});
        return;
    }

    const script_path = args[1];

    // Initialize PHP SAPI
    _ = php.php_embed_init(0, null);
    defer php.php_embed_shutdown();

    // Read the PHP script
    const file = try std.fs.cwd().openFile(script_path, .{});
    defer file.close();

    const script_content = try file.readToEndAlloc(allocator, 1024 * 1024); // 1MB max
    defer allocator.free(script_content);

    // Create a null-terminated string for PHP
    const script_content_z = try allocator.dupeZ(u8, script_content);
    defer allocator.free(script_content_z);

    // Execute the PHP script
    const result = php.zend_eval_string(
        script_content_z.ptr,
        null,
        script_path.ptr,
    );

    if (result == php.FAILURE) {
        std.debug.print("Error executing PHP script\n", .{});
        return error.PhpExecutionFailed;
    }

    std.debug.print("PHP script executed successfully\n", .{});
}
