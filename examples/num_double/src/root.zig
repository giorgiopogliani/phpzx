const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

pub inline fn num_double(value: c.zend_long) c.zend_long {
    return value * 2;
}

var module = phpzx.PhpModuleBuilder
    .new("basic")
    .function("num_double", num_double)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}
