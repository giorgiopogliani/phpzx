const std = @import("std");

const c = @import("include.zig").c;
const PhpModuleBuilder = @import("module.zig").PhpModuleBuilder;
const PhpFunctionEntry = @import("functions.zig").PhpFunctionEntry;
const PhpFunctionArgInfo = @import("functions.zig").PhpFunctionArgInfo;
const PhpType = @import("types.zig").PhpType;

pub inline fn num_double(value: c.zend_long) c.zend_long {
    return value * 2;
}

test "basic module" {
    const module = comptime PhpModuleBuilder
        .new("basic")
        .function("num_double", num_double)
        .build();

    try std.testing.expect(
        std.mem.eql(u8, std.mem.span(module.name), "basic"),
    );

    try std.testing.expect(
        std.mem.eql(u8, std.mem.span(module.functions[0].fname), "num_double"),
    );

    try std.testing.expect(
        module.functions[1].fname == null
    );

    std.debug.print("done!", .{});
}


const SampleObject = struct {
    value: c.zend_long,
    std: c.zend_object,
};

var sample_ce: *c.zend_class_entry = undefined;
var sample_handlers: c.zend_object_handlers = undefined;

fn zim_Sample___construct(execute_data: [*c]c.zend_execute_data, return_value: [*c]c.zval) callconv(.c) void {
    _ = execute_data;
    _ = return_value;
}

fn zim_Sample___getValue(execute_data: [*c]c.zend_execute_data, return_value: [*c]c.zval) callconv(.c) void {
    _ = execute_data;
    _ = return_value;
}
fn sample_create_obj(ce: [*c]c.zend_class_entry) callconv(.c) [*c]c.zend_object {
    const obj = @as(*SampleObject, @alignCast(@ptrCast(c.zend_object_alloc(@sizeOf(SampleObject), ce))));
    c.zend_object_std_init(&obj.*.std, ce);
    c.object_properties_init(&obj.*.std, ce);
    obj.*.std.handlers = &sample_handlers;
    return &obj.*.std;
}


pub fn sample_startup(a: c_int, b: c_int) callconv(.c) c.zend_result {
    _ = a;
    _ = b;

    const ce: c.zend_class_entry = undefined;
    // c.INIT_CLASS_ENTRY(ce, "Sample", sample_methods);
    sample_ce = c.zend_register_internal_class(@constCast(&ce));
    sample_ce.unnamed_1.create_object = sample_create_obj;
    // memcpy(&sample_handlers, zend_get_std_object_handlers(), sizeof(zend_object_handlers));
    return c.SUCCESS;
}


const sample_methods = [_]c.zend_function_entry{
    //
    PhpFunctionEntry.new(.{
        .name = "__construct",
        .handler = @ptrCast(&zim_Sample___construct),
        .arg_info = &[_]c.zend_internal_arg_info{
            //
            PhpFunctionArgInfo.empty(1),
            //
            PhpFunctionArgInfo.new("value", PhpType.Long),
        },
        .flags = c.ZEND_ACC_PUBLIC | c.ZEND_ACC_CTOR,
    }),
    PhpFunctionEntry.empty(),
};

test "module with class" {
  _ = comptime PhpModuleBuilder
      .new("basic")
      .minit(&sample_startup)
      .method(
        PhpFunctionEntry.new(.{
            .name = "__construct",
            .handler = @ptrCast(&zim_Sample___construct),
            .arg_info = &[_]c.zend_internal_arg_info{
                //
                PhpFunctionArgInfo.empty(1),
                //
                PhpFunctionArgInfo.new("value", PhpType.Long),
            },
            .flags = c.ZEND_ACC_PUBLIC | c.ZEND_ACC_CTOR,
        })
      )
      .build();

}
