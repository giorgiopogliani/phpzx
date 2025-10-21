const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

const PhpDiagnostic = phpzx.PhpDiagnostic;
const PhpFunction = phpzx.PhpFunction;
// const PhpFunctionEntry = phpzx.PhpFunctionEntry;
// const PhpFunctionEntry2 = phpzx.PhpFunctionEntry2;
const PhpFunctionEntryInfo = phpzx.PhpFunctionEntryInfo;
const PhpModuleBuilder = @import("module.zig");


pub inline fn num_double(value: c.zend_long) c.zend_long {
  return value * 2;
}

// Usage
var module = PhpModuleBuilder
    .new("basic")
    .function("num_double", num_double)
    .build();

pub export fn get_module() [*c]c.zend_module_entry {
    return &module;
}
