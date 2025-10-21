const ModuleBuilder = @This();

const c = @import("include.zig").c;

module: c.zend_module_entry,

pub fn new(name: []const u8) ModuleBuilder {
    return ModuleBuilder{ .module = c.zend_module_entry{
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
        .build_id = comptime std.fmt.comptimePrint("API{d}{s}", .{c.ZEND_MODULE_API_NO, c.ZEND_BUILD_TS}),
    } };
}

pub fn functions(builder: ModuleBuilder, comptime entries: [*]const c.zend_function_entry) ModuleBuilder {
    return ModuleBuilder{ .module = c.zend_module_entry{
        .size = builder.module.size,
        .zend_api = builder.module.zend_api,
        .zend_debug = builder.module.zend_debug,
        .zts = builder.module.zts,
        .ini_entry = builder.module.ini_entry,
        .deps = builder.module.deps,
        .name = builder.module.name,
        .functions = entries,
        .module_startup_func = builder.module.module_startup_func,
        .module_shutdown_func = builder.module.module_shutdown_func,
        .request_startup_func = builder.module.request_startup_func,
        .request_shutdown_func = builder.module.request_shutdown_func,
        .info_func = builder.module.info_func,
        .version = builder.module.version,
        .globals_size = builder.module.globals_size,
        .globals_ptr = builder.module.globals_ptr,
        .globals_ctor = builder.module.globals_ctor,
        .globals_dtor = builder.module.globals_dtor,
        .post_deactivate_func = builder.module.post_deactivate_func,
        .module_started = builder.module.module_started,
        .type = builder.module.type,
        .handle = builder.module.handle,
        .module_number = builder.module.module_number,
        .build_id = builder.module.build_id,
    } };
}

pub fn function(builder: ModuleBuilder, comptime entries: [*]const c.zend_function_entry) ModuleBuilder {
    var new_module = builder.module;
    new_module.functions = entries;
    return ModuleBuilder{ .module = new_module };
}

pub fn minit(builder: ModuleBuilder, comptime func: @TypeOf(builder.module.module_startup_func)) ModuleBuilder {
    return ModuleBuilder{ .module = c.zend_module_entry{
        .size = builder.module.size,
        .zend_api = builder.module.zend_api,
        .zend_debug = builder.module.zend_debug,
        .zts = builder.module.zts,
        .ini_entry = builder.module.ini_entry,
        .deps = builder.module.deps,
        .name = builder.module.name,
        .functions = func,
        .module_startup_func = builder.module.module_startup_func,
        .module_shutdown_func = builder.module.module_shutdown_func,
        .request_startup_func = builder.module.request_startup_func,
        .request_shutdown_func = builder.module.request_shutdown_func,
        .info_func = builder.module.info_func,
        .version = builder.module.version,
        .globals_size = builder.module.globals_size,
        .globals_ptr = builder.module.globals_ptr,
        .globals_ctor = builder.module.globals_ctor,
        .globals_dtor = builder.module.globals_dtor,
        .post_deactivate_func = builder.module.post_deactivate_func,
        .module_started = builder.module.module_started,
        .type = builder.module.type,
        .handle = builder.module.handle,
        .module_number = builder.module.module_number,
        .build_id = builder.module.build_id,
    } };
}

pub fn build(builder: ModuleBuilder) c.zend_module_entry {
    return builder.module;
}

const std = @import("std");
const expect = std.testing.expect;

test "can build a module" {
    comptime {
        const methods: [2]c.zend_function_entry = [2]c.zend_function_entry{
            c.zend_function_entry{
                .fname = "__construct",
                .handler = null,
                .arg_info = null,
                .num_args = 0,
                .flags = 0,
                .frameless_function_infos = null,
                .doc_comment = null,
            },
            c.zend_function_entry{
                .fname = null,
                .handler = null,
                .arg_info = null,
                .num_args = 0,
                .flags = 0,
                .frameless_function_infos = null,
                .doc_comment = null,
            },
        };

        const builder = ModuleBuilder.new("test_module").functions(&methods).build();

        std.debug.print("build id {}\n", .{builder.module.build_id});
    }

    try expect(true);
}
