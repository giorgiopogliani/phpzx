const ModuleBuilder = @This();

const c = @import("php.zig");

module: c.zend_module_entry,

fn build(name: []const u8) c.zend_module_entry {
    return c.zend_module_entry{
        .size = @sizeOf(c.zend_module_entry),
        .zend_api = 20240924,
        .zend_debug = 0,
        .zts = 0,
        .ini_entry = null,
        .deps = null,
        .name = name,
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
        .build_id = c.ZEND_MODULE_BUILD_ID,
    };
}
