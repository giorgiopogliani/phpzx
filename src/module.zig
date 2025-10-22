pub const PhpModuleBuilder = @This();

const std = @import("std");
const expect = std.testing.expect;
const c = @import("include.zig").c;
const PhpFunctionEntry = @import("functions.zig").PhpFunctionEntry;

module: c.zend_module_entry,

function_entries: []const c.zend_function_entry = &[_]c.zend_function_entry{},

pub fn new(name: []const u8) PhpModuleBuilder {
    return PhpModuleBuilder{ .module = c.zend_module_entry{
        .size = @as(c_ushort, @bitCast(@as(c_ushort, @truncate(@sizeOf(c.zend_module_entry))))),
        .zend_api = c.ZEND_MODULE_API_NO,
        .zend_debug = @as(u8, @bitCast(@as(i8, @truncate(c.ZEND_DEBUG)))),
        .zts = @as(u8, @bitCast(@as(i8, @truncate(c.USING_ZTS)))),
        .ini_entry = null,
        .deps = null,
        .name = @ptrCast(name),
        .functions = null,
        .module_startup_func = null,
        .module_shutdown_func = null,
        .request_startup_func = null,
        .request_shutdown_func = null,
        .info_func = null,
        .version = null,
        .globals_size = 0,
        .globals_ptr = null,
        .globals_ctor = null,
        .globals_dtor = null,
        .post_deactivate_func = null,
        .module_started = 0,
        .type = 0,
        .handle = null,
        .module_number = 0,
        .build_id = comptime std.fmt.comptimePrint("API{d}{s}", .{ c.ZEND_MODULE_API_NO, c.ZEND_BUILD_TS }),
    } };
}

pub fn functions(comptime builder: PhpModuleBuilder, comptime entries: []const c.zend_function_entry) PhpModuleBuilder {
    var result = builder.module;
    result.functions = entries;
    return PhpModuleBuilder{ .module = result };
}

pub fn method(comptime builder: PhpModuleBuilder, comptime entry: c.zend_function_entry) PhpModuleBuilder {
    return PhpModuleBuilder{
      .module = builder.module,
      .function_entries = builder.function_entries ++ [_]c.zend_function_entry{entry},
    };
}

pub fn function(comptime builder: PhpModuleBuilder, comptime name: []const u8, comptime handler: anytype) PhpModuleBuilder {
    const Handler = struct {
        pub const handle = handler;
    };

    const new_entry = PhpFunctionEntry.from(name, Handler);

    return .{
        .module = builder.module,
        .function_entries = builder.function_entries ++ [_]c.zend_function_entry{new_entry},
    };
}

pub fn minit(comptime builder: PhpModuleBuilder, comptime func: @TypeOf(builder.module.module_startup_func)) PhpModuleBuilder {
    var result = builder.module;
    result.module_startup_func = func;
    return PhpModuleBuilder{ .module = result };
}

pub fn build(comptime builder: PhpModuleBuilder) c.zend_module_entry {
    const final_entries = builder.function_entries ++ [_]c.zend_function_entry{PhpFunctionEntry.empty()};
    var result = builder.module;
    result.functions = final_entries;
    return result;
}
