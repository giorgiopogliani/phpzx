const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

const PhpDiagnostic = phpzx.PhpDiagnostic;
const PhpFunction = phpzx.PhpFunction;
const PhpFunctionEntry = phpzx.PhpFunctionEntry;
const PhpFunctionEntry2 = phpzx.PhpFunctionEntry2;
const PhpFunctionEntryInfo = phpzx.PhpFunctionEntryInfo;

// Usage
var module = phpzx.ModuleBuilder.new("basic")
    .functions(&[_]c.zend_function_entry{
        PhpFunctionEntry2.new("num_double", struct {
            pub inline fn handle(value: c.zend_long) c.zend_long {
                return value * 2;
            }
        }),
        PhpFunctionEntry.empty(),
    })
    .build();

pub export fn get_module() [*c]c.zend_module_entry {
    return &module;
}
