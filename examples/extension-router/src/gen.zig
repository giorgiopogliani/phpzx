const std = @import("std");
const root = @import("root"); // your main module

pub fn main() !void {
    const file = try std.fs.cwd().createFile("php_glue.zig", .{ .truncate = true });
    defer file.close();

    inline for (@typeInfo(root).@"struct".decls) |decl| {
        const decl_val = @field(root, decl.name);
        const decl_type = @TypeOf(decl_val);

        if (comptime decl_type == .Struct) {

        }

        std.debug.print("what now: {s}\n", .{  });

        // comptime if (std.mem.eql(u8, @typeInfo(decl_type),  "struct") and @hasField(decl_type, "expose_to_php")) {
        //     try file.writeAll("export fn {s}_new() *{s} {\n", .{ decl.name });
        //     try file.writeAll("    return std.heap.c_allocator.create({s}) catch null;\n", .{ decl.name });
        //     try file.writeAll("}\n\n", .{});

        //     for (@typeInfo(decl_type).Struct.decls) |fn_decl| {
        //         if (@typeInfo(@TypeOf(@field(decl_type, fn_decl.name))) == .Fn) {
        //             try file.writeAll("export fn {s}_{s}_wrap(self: *{s}) void {\n", .{ decl.name, fn_decl.name, decl.name });
        //             try file.writeAll("    _ = self.{s}();\n", .{ fn_decl.name });
        //             try file.writeAll("}\n\n", .{});
        //         }
        //     }
        // };
    }
}
