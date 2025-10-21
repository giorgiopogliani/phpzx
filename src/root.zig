const std = @import("std");
pub const ModuleBuilder = @import("module.zig");
pub const c = @import("include.zig").c;

/// Errors codes ported from PHP source code
pub const PhpError = error{
    ErrorFailure, //  1
    ErrorWrongCallback, //  2
    ErrorWrongClass, //  3
    ErrorWrongClassOrNull, //  4
    ErrorWrongClassOrString, //  5
    ErrorWrongClassOrStringOrNull, //  6
    ErrorWrongClassOrLong, //  7
    ErrorWrongClassOrLongOrNull, //  8
    ErrorWrongArg, //  9
    ErrorWrongCount, // 10
    ErrorUnexpectedExtraNamed, // 11
    ErrorWrongCallbackOrNull, // 12
    /// Custom error codes
    ErrorUnexpectedType,
};

pub const PhpType = enum(u8) {
    Undef = c.IS_UNDEF,
    Null = c.IS_NULL,
    False = c.IS_FALSE,
    True = c.IS_TRUE,
    Long = c.IS_LONG,
    Double = c.IS_DOUBLE,
    String = c.IS_STRING,
    Array = c.IS_ARRAY,
    Object = c.IS_OBJECT,
    Resource = c.IS_RESOURCE,
    Reference = c.IS_REFERENCE,
    ConstantAst = c.IS_CONSTANT_AST,
    Callable = c.IS_CALLABLE,
    Iterable = c.IS_ITERABLE,
    Void = c.IS_VOID,
    Static = c.IS_STATIC,
    Mixed = c.IS_MIXED,
    Never = c.IS_NEVER
};

/// Expected type enums
pub const PhpExpectedType = enum(c_int) {
    Long = c.Z_EXPECTED_LONG,
    LongOrNull = c.Z_EXPECTED_LONG_OR_NULL,
    Bool = c.Z_EXPECTED_BOOL,
    BoolOrNull = c.Z_EXPECTED_BOOL_OR_NULL,
    String = c.Z_EXPECTED_STRING,
    StringOrNull = c.Z_EXPECTED_STRING_OR_NULL,
    Array = c.Z_EXPECTED_ARRAY,
    ArrayOrNull = c.Z_EXPECTED_ARRAY_OR_NULL,
    ArrayOrLong = c.Z_EXPECTED_ARRAY_OR_LONG,
    ArrayOrLongOrNull = c.Z_EXPECTED_ARRAY_OR_LONG_OR_NULL,
    Iterable = c.Z_EXPECTED_ITERABLE,
    IterableOrNull = c.Z_EXPECTED_ITERABLE_OR_NULL,
    Func = c.Z_EXPECTED_FUNC,
    FuncOrNull = c.Z_EXPECTED_FUNC_OR_NULL,
    Resource = c.Z_EXPECTED_RESOURCE,
    ResourceOrNull = c.Z_EXPECTED_RESOURCE_OR_NULL,
    Path = c.Z_EXPECTED_PATH,
    PathOrNull = c.Z_EXPECTED_PATH_OR_NULL,
    Object = c.Z_EXPECTED_OBJECT,
    ObjectOrNull = c.Z_EXPECTED_OBJECT_OR_NULL,
    Double = c.Z_EXPECTED_DOUBLE,
    DoubleOrNull = c.Z_EXPECTED_DOUBLE_OR_NULL,
    Number = c.Z_EXPECTED_NUMBER,
    NumberOrNull = c.Z_EXPECTED_NUMBER_OR_NULL,
    NumberOrString = c.Z_EXPECTED_NUMBER_OR_STRING,
    NumberOrStringOrNull = c.Z_EXPECTED_NUMBER_OR_STRING_OR_NULL,
    ArrayOrString = c.Z_EXPECTED_ARRAY_OR_STRING,
    ArrayOrStringOrNull = c.Z_EXPECTED_ARRAY_OR_STRING_OR_NULL,
    StringOrLong = c.Z_EXPECTED_STRING_OR_LONG,
    StringOrLongOrNull = c.Z_EXPECTED_STRING_OR_LONG_OR_NULL,
    ObjectOrClassName = c.Z_EXPECTED_OBJECT_OR_CLASS_NAME,
    ObjectOrClassNameOrNull = c.Z_EXPECTED_OBJECT_OR_CLASS_NAME_OR_NULL,
    ObjectOrString = c.Z_EXPECTED_OBJECT_OR_STRING,
    ObjectOrStringOrNull = c.Z_EXPECTED_OBJECT_OR_STRING_OR_NULL,
    Last = c.Z_EXPECTED_LAST,
};

/// Optional diagnostics used for reporting useful errors
pub const PhpDiagnostic = struct {
    min_num_args: u32 = 0,
    max_num_args: u32 = 0,
    num_arg: u32 = 1,
    err: [*c]u8 = null,
    expected_type: c_uint = c.Z_EXPECTED_LONG,
    args: [*c]c.zval = null,

    pub fn report(diag: PhpDiagnostic, err: PhpError) void {
        switch (err) {
            PhpError.ErrorWrongCount => {
                c.zend_wrong_parameters_count_error(diag.min_num_args, diag.max_num_args);
            },
            PhpError.ErrorWrongCallbackOrNull => {
                c.zend_wrong_parameter_error(c.ZPP_ERROR_WRONG_CALLBACK_OR_NULL, diag.num_arg, diag.err, diag.expected_type, diag.args);
            },
            PhpError.ErrorUnexpectedType => {
                c.zend_wrong_parameter_type_error(diag.num_arg, diag.expected_type, diag.args);
            },
            else => {},
        }
    }
};

/// Php Function Entry wrapper for creating zend_function_entry
pub const PhpFunctionEntry = struct {
    pub fn new(options: struct { name: [*c]const u8, handler: c.zif_handler, arg_info: []const c.zend_internal_arg_info}) c.zend_function_entry {
        return c.zend_function_entry{
            .fname = options.name,
            .handler = options.handler,
            .arg_info = @as([*c]c.zend_internal_arg_info, @constCast(&options.arg_info[0])),
            .num_args = if (options.arg_info.len > 0) options.arg_info.len else 0,
            .flags = 0,
            .frameless_function_infos = null,
            .doc_comment = null,
        };
    }

    pub fn empty() c.zend_function_entry {
        return c.zend_function_entry{
            .fname = null,
            .handler = null,
            .arg_info = null,
            .num_args = 0,
            .flags = 0,
            .frameless_function_infos = null,
            .doc_comment = null,
        };
    }
};

pub const PhpFunctionEntry2 = struct {
    pub fn new(comptime name: []const u8, comptime Handler: type) c.zend_function_entry {
        const impl = struct {
            fn zif(execute_data: [*c]c.zend_execute_data, return_value: [*c]c.zval) callconv(.c) void {
                const handler_fn = Handler.handle;
                const fn_info = @typeInfo(@TypeOf(handler_fn)).@"fn";
                const params = fn_info.params;

                var diag = PhpDiagnostic{};
                var func = PhpFunction.new(execute_data);
                check_args_count(&diag, &func, params.len, params.len) catch |err| {
                    diag.report(err);
                    return;
                };

                var args: std.meta.ArgsTuple(@TypeOf(handler_fn)) = undefined;
                inline for (params, 0..) |param, i| {
                    if (param.type.? == c.zend_long) {
                        parse_arg_long(&diag, &func, i + 1, &args[i]) catch |err| {
                            diag.report(err);
                            return;
                        };
                    }
                }

                const result = @call(.auto, handler_fn, args);

                if (fn_info.return_type.? == c.zend_long) {
                    set_zval_long(return_value, result);
                }
            }
        }.zif;

        @export(&impl, .{ .name = "zif_" ++ name });

        return PhpFunctionEntry.new(.{
          .name = @as([*]const u8, @ptrCast(name)),
          .handler = @as(?*const fn () callconv(.c) void, @ptrCast(&impl)),
          .arg_info = &[2]c.zend_internal_arg_info{
            PhpFunctionEntryInfo.empty(1),
            PhpFunctionEntryInfo.new("value", PhpType.Long),
        } });
    }
};

/// Php Function Entry Info wrapper for creating zend_internal_arg_info
pub const PhpFunctionEntryInfo = struct {
    pub fn empty(args: usize) c.zend_internal_arg_info {
        return c.zend_internal_arg_info{
            .name = @as([*c]const u8, @ptrFromInt(@as(usize, @bitCast(@as(c_long, @as(c_int, args)))))),
            .type = c.zend_type{
                .ptr = @as(?*anyopaque, @ptrFromInt(@as(c_int, 2))),
                .type_mask = c.IS_NULL,
            },
            .default_value = null,
        };
    }

    pub fn new(arg_name: [*c]const u8, arg_type: PhpType) c.zend_internal_arg_info {
        return c.zend_internal_arg_info{
            .name = arg_name,
            .type = c.zend_type{
                .ptr = @as(?*anyopaque, @ptrFromInt(@as(c_int, 2))),
                .type_mask = @intFromEnum(arg_type),
            },
            .default_value = null,
        };
    }
};

/// Php array wrapper
// Simple iterator for PHP HashTable
pub const PhpArray = struct {
    table: *c.HashTable,
    current: [*c]c.zval,
    end: [*c]c.zval,
    index: c_uint,

    pub inline fn new(php_val: *c.zval, size: u32) PhpArray {
        c.array_init_size(php_val, size);
        const table = c.Z_ARRVAL_P(php_val);
        c.zend_hash_real_init_packed(table);

        return PhpArray{
            .table = table,
            .current = table.*.unnamed_0.arPacked,
            .end = table.*.unnamed_0.arPacked + table.*.nNumUsed,
            .index = table.*.nNumUsed,
        };
    }

    pub inline fn from(php_val: [*c]c.zval) PhpArray {
        const table = c.Z_ARRVAL_P(php_val);
        return PhpArray{
            .table = table,
            .current = table.*.unnamed_0.arPacked,
            .end = table.*.unnamed_0.arPacked + table.*.nNumUsed,
            .index = table.*.nNumUsed,
        };
    }

    pub inline fn hasNext(self: *const PhpArray) bool {
        return self.current != self.end;
    }

    pub inline fn next(self: *PhpArray) *c.zval {
        self.current += 1;
        self.index +%= 1;
        return self.current;
    }

    pub inline fn fill(self: *PhpArray, result: [*c]c.zval) void {
        const _z1: [*c]c.zval = self.current;
        const _z2: [*c]const c.zval = result;
        const _gc: [*c]c.zend_refcounted = _z2.*.value.counted;
        const _t: u32 = _z2.*.u1.type_info;
        _z1.*.value.counted = _gc;
        _z1.*.u1.type_info = _t;
        self.current += 1;
        self.index +%= 1;
    }

    pub inline fn reset(self: *PhpArray) void {
        self.current = self.table.unnamed_0.arPacked;
        self.index = 0;
    }

    // Helper to finalize hashtable
    pub inline fn finalize(self: *PhpArray) void {
        self.table.*.nNumOfElements +%= self.index - self.table.nNumUsed;
        self.table.*.nNumUsed = self.index;
        self.table.*.nNextFreeElement = @as(c.zend_long, @bitCast(@as(c_ulonglong, self.index)));
        self.table.*.nInternalPointer = 0;
    }

    pub inline fn destroy(self: *PhpArray) void {
        c.zend_array_destroy(self.table);
    }
};

/// Struct to hold information about a PHP function.
pub const PhpFunction = struct {
    args_count: u32 = 0,
    args: [*c]c.zval = null,

    pub fn new(execute_data: [*c]c.zend_execute_data) PhpFunction {
        return .{
            .args = ZEND_CALL_ARG(execute_data, 0),
            .args_count = c.ZEND_CALL_NUM_ARGS(execute_data),
        };
    }
};

/// Struct to hold information about a PHP function argument.
pub const PhpFunctionArgument = struct {
    index: c_int = 1,
};

/// Parse variadic arguments into a pointer to an array of zvals and the number of elements.
pub inline fn parse_arg_variadic(diag: *PhpDiagnostic, func: *PhpFunction, arg_index: usize, dest: *[*c]c.zval, dest_num: *c_int) !void {
    _ = diag;
    const num_varargs = func.args_count - (arg_index - 1);
    if (num_varargs > 0) {
        dest.* = func.args + arg_index;
        dest_num.* = @intCast(num_varargs);
    } else {
        // No variadic arguments
        dest.* = null;
        dest_num.* = 0;
        return PhpError.ErrorUnexpectedExtraNamed;
    }
}

/// Parse a closure argument into a pointer to a zend_fcall_info and a zend_fcall_info_cache.
pub inline fn parse_arg_closure(diag: *PhpDiagnostic, func: *PhpFunction, arg_index: usize, fci: *c.zend_fcall_info, fci_cache: *c.zend_fcall_info_cache) PhpError!void {
    var error_msg: [*c]u8 = null;
    // Parse the function argument - simplified condition check
    const success = c.zend_parse_arg_func(func.args + arg_index, fci, fci_cache, true, &error_msg, true);
    if (!success) {
        @branchHint(.unlikely);
        diag.* = .{ .num_arg = arg_index, .err = error_msg, .expected_type = c.Z_EXPECTED_FUNC_OR_NULL, .args = func.args };
        // Handle parsing errors with proper error messages
        if (error_msg == null) {
            diag.expected_type = c.ZPP_ERROR_WRONG_CALLBACK_OR_NULL;
            return PhpError.ErrorWrongArg;
        } else {
            return PhpError.ErrorWrongCallbackOrNull;
        }
    }
}

/// Parse long
pub inline fn parse_arg_long(diag: *PhpDiagnostic, func: *const PhpFunction, arg_index: usize, long: *c.zend_long) PhpError!void {
    _ = diag;
    _ = arg_index;
    // TODO: check type
    long.* = c.zval_get_long(func.args + 1);
}

/// Check zval type
pub inline fn check_arg_type(diag: *PhpDiagnostic, arg_index: usize, php_val: [*c]c.zval, php_type: PhpType) !void {
    // TODO: update to check on multiple types
    if (c.zval_get_type(php_val) != @intFromEnum(php_type)) {
        diag.num_arg = arg_index;
        diag.expected_type = @intFromEnum(php_type);
        diag.args = php_val;
        return PhpError.ErrorUnexpectedType;
    }
}

/// Check if the number of arguments respect the expected range
pub inline fn check_args_count(diag: *PhpDiagnostic, func: *const PhpFunction, comptime min_num_args: u32, comptime max_num_args: u32) !void {
    if (func.args_count < min_num_args or func.args_count > max_num_args) {
        @branchHint(.unlikely);

        diag.* = .{ .min_num_args = min_num_args, .max_num_args = max_num_args };

        return PhpError.ErrorWrongCount;
    }
}

pub inline fn set_zval_long(zval: *c.zval, value: c.zend_long) void {
    zval.*.value.lval = value;
    zval.*.u1.type_info = @intFromEnum(PhpType.Long);
}

pub inline fn ZEND_CALL_VAR_NUM(call: anytype, n: anytype) [*]c.zval {
    const call_ptr: [*c]c.zval = @ptrCast(call);
    const offset: c_int = @intCast(n);
    const result_ptr = call_ptr + (c.ZEND_CALL_FRAME_SLOT + offset);
    return @as([*]c.zval, @ptrCast(result_ptr));
}

pub inline fn ZEND_CALL_ARG(call: anytype, n: anytype) [*]c.zval {
    const arg_n: c_int = @intCast(n);
    return ZEND_CALL_VAR_NUM(call, arg_n - 1);
}
