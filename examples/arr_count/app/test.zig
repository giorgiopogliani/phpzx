const PhpFunctionEntry = struct {
    name: [*c]const u8,
    handler: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void,
};

const PhpModuleEntry = struct {
    module: [*c]php.zend_module_entry,

    fn new(comptime N: usize, functions: [N]PhpFunctionEntry) PhpModuleEntry {
        const entries: [*c]php.zend_function_entry = []php.zend_function_entry{};

        const arg_info: [*c]php.struct__zend_internal_arg_info = undefined;

        inline for (functions, 0..) |s, i| {
            entries[i] = php.zend_function_entry{
                .fname = s.name,
                .handler = @ptrCast(s.handler),
                .arg_info = arg_info,
                .flags = 0,
                .num_args = 0,
                .frameless_function_infos = null,
                .doc_comment = null,
            };
        }

        return PhpModuleEntry{
            .module = &.{
                php.STANDARD_MODULE_HEADER,
                "myext",
                entries,
                null, // MINIT
                null, // MSHUTDOWN
                null, // RINIT
                null, // RSHUTDOWN
                null, // MINFO
                "1.0", // Version
                php.STANDARD_MODULE_PROPERTIES,
            },
        };
    }

};


const funcs = [_]PhpFunctionEntry{
  .{ .name = "num_double", .handler = @ptrCast(&num_double.zif_num_double) },
};

const module = PhpModuleEntry.new(funcs.len, funcs);

pub export fn get_module() [*c]php.zend_module_entry {
    return module.module;
}
