const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

pub inline fn num_double(value: phpzx.types.PhpInt) phpzx.types.PhpInt {
    return value * 2;
}

pub inline fn num_double2(value: i64) i64 {
    return value * 2;
}

var module = phpzx.PhpModuleBuilder
    .new("basic")
    .function("num_double", num_double)
    .function("num_double2", num_double2)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}
