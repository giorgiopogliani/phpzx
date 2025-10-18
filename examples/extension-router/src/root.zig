const std = @import("std");
const c = @import("phpzx").c;
const cc = @cImport({
    @cInclude("string.h");
});
const phpzx = @import("phpzx");

pub const strlen = cc.strlen;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;

const PhpDiagnostic = phpzx.PhpDiagnostic;
const PhpFunction = phpzx.PhpFunction;

pub const Sample = struct {
    std: c.zend_object,
    name: []const u8,

    pub fn __construct(self: *Sample, name: []const u8) void {
        self.name = name;
    }

    pub fn getName(self: *Sample) []const u8 {
        return self.name;
    }
};

pub export fn zim_Sample___construct(arg_execute_data: [*c]c.zend_execute_data, arg_return_value: *c.zval) void {
    _ = arg_execute_data;
    _ = arg_return_value;
}

// name: []const u8,
// methods: [*]c.zend_function_entry,
pub var sample_ce: *c.zend_class_entry = undefined;
pub var sample_handlers: c.zend_object_handlers = undefined;

// pub fn new(comptime object: type, name: []const u8, methods: [*]c.zend_function_entry) PhpClass {
//     return struct {
//         name = name,
//         methods = methods,
//         ce = undefined,
//         handlers = undefined,
//         object = object,
//     };
// }

pub fn sample_create_obj(ce: *c.zend_class_entry) *c.zend_object {
    const obj: *Sample = @as(*Sample, @ptrCast(@alignCast(c.zend_object_alloc(@sizeOf(Sample), ce))));
    c.zend_object_std_init(&obj.*.std, ce);
    c.object_properties_init(&obj.*.std, ce);
    return &obj.*.std;
}

pub const sample_methods: [2]c.zend_function_entry = [2]c.zend_function_entry{
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

pub export fn zm_startup_sample(arg_type: c_int, arg_module_number: c_int) c.zend_result {
    var @"type" = arg_type;
    _ = &@"type";
    var module_number = arg_module_number;
    _ = &module_number;
    var ce: c.zend_class_entry = undefined;
    _ = &ce;
    {
        _ = __builtin___memset_chk(@as(?*anyopaque, @ptrCast(&ce)), @as(c_int, 0), @sizeOf(c.zend_class_entry), __builtin_object_size(@as(?*const anyopaque, @ptrCast(&ce)), @as(c_int, 0)));
        ce.name = c.zend_string_init_interned.?("Sample", strlen("Sample"), @as(c_int, 1) != 0);
        // ce.default_object_handlers = &std_object_handlers;
        ce.info.internal.builtin_functions = @as([*c]const c.zend_function_entry, @ptrCast(@alignCast(&sample_methods[@as(usize, @intCast(0))])));
    }

    sample_ce = c.zend_register_internal_class(&ce);
    sample_ce.*.unnamed_1.create_object = @ptrCast(&sample_create_obj);

    return c.SUCCESS;
}

const ModuleBuilder = struct {
  module: c.zend_module_entry,

  fn build() c.zend_module_entry {
    return c.zend_module_entry{
        .size = @sizeOf(c.zend_module_entry),
        .zend_api = 20240924,
        .zend_debug = 0,
        .zts = 0,
        .ini_entry = null,
        .deps = null,
        .name = "sample",
        .functions = null,
        .module_startup_func = &zm_startup_sample,
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
        .build_id = "API20240924,NTS",
    };
  }
};


pub export var sample_module_entry: c.zend_module_entry = ModuleBuilder.build();

pub export fn get_module() *c.zend_module_entry {
    return &sample_module_entry;
}
