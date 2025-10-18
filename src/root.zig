const std = @import("std");
const php = @import("php.zig");
pub const c = php;

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

pub const PhpType = enum(u8) { Undef = php.IS_UNDEF, Null = php.IS_NULL, False = php.IS_FALSE, True = php.IS_TRUE, Long = php.IS_LONG, Double = php.IS_DOUBLE, String = php.IS_STRING, Array = php.IS_ARRAY, Object = php.IS_OBJECT, Resource = php.IS_RESOURCE, Reference = php.IS_REFERENCE, ConstantAst = php.IS_CONSTANT_AST, Callable = php.IS_CALLABLE, Iterable = php.IS_ITERABLE, Void = php.IS_VOID, Static = php.IS_STATIC, Mixed = php.IS_MIXED, Never = php.IS_NEVER };

/// Expected type enums
pub const PhpExpectedType = enum(c_int) {
    Long = php.Z_EXPECTED_LONG,
    LongOrNull = php.Z_EXPECTED_LONG_OR_NULL,
    Bool = php.Z_EXPECTED_BOOL,
    BoolOrNull = php.Z_EXPECTED_BOOL_OR_NULL,
    String = php.Z_EXPECTED_STRING,
    StringOrNull = php.Z_EXPECTED_STRING_OR_NULL,
    Array = php.Z_EXPECTED_ARRAY,
    ArrayOrNull = php.Z_EXPECTED_ARRAY_OR_NULL,
    ArrayOrLong = php.Z_EXPECTED_ARRAY_OR_LONG,
    ArrayOrLongOrNull = php.Z_EXPECTED_ARRAY_OR_LONG_OR_NULL,
    Iterable = php.Z_EXPECTED_ITERABLE,
    IterableOrNull = php.Z_EXPECTED_ITERABLE_OR_NULL,
    Func = php.Z_EXPECTED_FUNC,
    FuncOrNull = php.Z_EXPECTED_FUNC_OR_NULL,
    Resource = php.Z_EXPECTED_RESOURCE,
    ResourceOrNull = php.Z_EXPECTED_RESOURCE_OR_NULL,
    Path = php.Z_EXPECTED_PATH,
    PathOrNull = php.Z_EXPECTED_PATH_OR_NULL,
    Object = php.Z_EXPECTED_OBJECT,
    ObjectOrNull = php.Z_EXPECTED_OBJECT_OR_NULL,
    Double = php.Z_EXPECTED_DOUBLE,
    DoubleOrNull = php.Z_EXPECTED_DOUBLE_OR_NULL,
    Number = php.Z_EXPECTED_NUMBER,
    NumberOrNull = php.Z_EXPECTED_NUMBER_OR_NULL,
    NumberOrString = php.Z_EXPECTED_NUMBER_OR_STRING,
    NumberOrStringOrNull = php.Z_EXPECTED_NUMBER_OR_STRING_OR_NULL,
    ArrayOrString = php.Z_EXPECTED_ARRAY_OR_STRING,
    ArrayOrStringOrNull = php.Z_EXPECTED_ARRAY_OR_STRING_OR_NULL,
    StringOrLong = php.Z_EXPECTED_STRING_OR_LONG,
    StringOrLongOrNull = php.Z_EXPECTED_STRING_OR_LONG_OR_NULL,
    ObjectOrClassName = php.Z_EXPECTED_OBJECT_OR_CLASS_NAME,
    ObjectOrClassNameOrNull = php.Z_EXPECTED_OBJECT_OR_CLASS_NAME_OR_NULL,
    ObjectOrString = php.Z_EXPECTED_OBJECT_OR_STRING,
    ObjectOrStringOrNull = php.Z_EXPECTED_OBJECT_OR_STRING_OR_NULL,
    Last = php.Z_EXPECTED_LAST,
};

/// Optional diagnostics used for reporting useful errors
pub const PhpDiagnostic = struct {
    min_num_args: u32 = 0,
    max_num_args: u32 = 0,
    num_arg: u32 = 1,
    err: [*c]u8 = null,
    expected_type: c_uint = php.Z_EXPECTED_LONG,
    args: [*c]php.zval = null,

    pub fn report(diag: PhpDiagnostic, err: PhpError) void {
        switch (err) {
            PhpError.ErrorWrongCount => {
                php.zend_wrong_parameters_count_error(diag.min_num_args, diag.max_num_args);
            },
            PhpError.ErrorWrongCallbackOrNull => {
                php.zend_wrong_parameter_error(php.ZPP_ERROR_WRONG_CALLBACK_OR_NULL, diag.num_arg, diag.err, diag.expected_type, diag.args);
            },
            PhpError.ErrorUnexpectedType => {
                php.zend_wrong_parameter_type_error(diag.num_arg, diag.expected_type, diag.args);
            },
            else => {},
        }
    }
};

/// Php array wrapper
// Simple iterator for PHP HashTable
pub const PhpArray = struct {
    table: *php.HashTable,
    current: [*c]php.zval,
    end: [*c]php.zval,
    index: c_uint,

    pub inline fn new(php_val: *php.zval, size: u32) PhpArray {
        php.array_init_size(php_val, size);
        const table = php.Z_ARRVAL_P(php_val);
        php.zend_hash_real_init_packed(table);

        return PhpArray{
            .table = table,
            .current = table.*.unnamed_0.arPacked,
            .end = table.*.unnamed_0.arPacked + table.*.nNumUsed,
            .index = table.*.nNumUsed,
        };
    }

    pub inline fn from(php_val: [*c]php.zval) PhpArray {
        const table = php.Z_ARRVAL_P(php_val);
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

    pub inline fn next(self: *PhpArray) *php.zval {
        self.current += 1;
        self.index +%= 1;
        return self.current;
    }

    pub inline fn fill(self: *PhpArray, result: [*c]php.zval) void {
        const _z1: [*c]php.zval = self.current;
        const _z2: [*c]const php.zval = result;
        const _gc: [*c]php.zend_refcounted = _z2.*.value.counted;
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
        self.table.*.nNextFreeElement = @as(php.zend_long, @bitCast(@as(c_ulonglong, self.index)));
        self.table.*.nInternalPointer = 0;
    }

    pub inline fn destroy(self: *PhpArray) void {
        php.zend_array_destroy(self.table);
    }
};

/// Struct to hold information about a PHP function.
pub const PhpFunction = struct {
    args_count: u32 = 0,
    args: [*c]php.zval = null,

    pub fn new(execute_data: [*c]php.zend_execute_data) PhpFunction {
        return .{
            .args = php.ZEND_CALL_ARG(execute_data, 0),
            .args_count = php.ZEND_CALL_NUM_ARGS(execute_data),
        };
    }
};

/// Struct to hold information about a PHP function argument.
pub const PhpFunctionArgument = struct {
    index: c_int = 1,
};

/// Parse variadic arguments into a pointer to an array of zvals and the number of elements.
pub inline fn parse_arg_variadic(diag: *PhpDiagnostic, func: *PhpFunction, arg_index: usize, dest: *[*c]php.zval, dest_num: *c_int) !void {
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
pub inline fn parse_arg_closure(diag: *PhpDiagnostic, func: *PhpFunction, arg_index: usize, fci: *php.zend_fcall_info, fci_cache: *php.zend_fcall_info_cache) PhpError!void {
    var error_msg: [*c]u8 = null;
    // Parse the function argument - simplified condition check
    const success = php.zend_parse_arg_func(func.args + arg_index, fci, fci_cache, true, &error_msg, true);
    if (!success) {
        @branchHint(.unlikely);
        diag.* = .{ .num_arg = arg_index, .err = error_msg, .expected_type = php.Z_EXPECTED_FUNC_OR_NULL, .args = func.args };
        // Handle parsing errors with proper error messages
        if (error_msg == null) {
            diag.expected_type = php.ZPP_ERROR_WRONG_CALLBACK_OR_NULL;
            return PhpError.ErrorWrongArg;
        } else {
            return PhpError.ErrorWrongCallbackOrNull;
        }
    }
}

/// Parse long
pub inline fn parse_arg_long(diag: *PhpDiagnostic, func: *const PhpFunction, arg_index: usize, long: *php.zend_long) PhpError!void {
    _ = diag;
    _ = arg_index;
    // TODO: check type
    long.* = php.zval_get_long(func.args + 1);
}

/// Check zval type
pub inline fn check_arg_type(diag: *PhpDiagnostic, arg_index: usize, php_val: [*c]php.zval, php_type: PhpType) !void {
    // TODO: update to check on multiple types
    if (php.zval_get_type(php_val) != @intFromEnum(php_type)) {
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

pub inline fn set_zval_long(zval: *php.zval, value: php.zend_long) void {
    zval.*.value.lval = value;
    zval.*.u1.type_info = @intFromEnum(PhpType.Long);
}

pub fn PhpDefineClass(comptime T: type, comptime methods: [*]c.zend_function_entry) type {
    return struct {
        object: T,
        ce: *c.zend_class_entry = undefined,
        handlers: c.zend_object_handlers = undefined,
        methods: [*]c.zend_function_entry = methods,

        pub fn sample_create_obj(self: *T, ce: *c.zend_class_entry) *c.zend_object {
            const obj: *T = @as(*self.object, @ptrCast(@alignCast(c.zend_object_alloc(@sizeOf(T), ce))));
            c.zend_object_std_init(&obj.*.std, ce);
            c.object_properties_init(&obj.*.std, ce);
            return &obj.*.std;
        }

        pub export fn zm_startup_sample(self: *T, arg_type: c_int, arg_module_number: c_int) c.zend_result {
            var @"type" = arg_type;
            _ = &@"type";
            var module_number = arg_module_number;
            _ = &module_number;
            var ce: c.zend_class_entry = undefined;
            _ = &ce;
            {
                _ = c.__builtin___memset_chk(@as(?*anyopaque, @ptrCast(&ce)), @as(c_int, 0), @sizeOf(c.zend_class_entry), c.__builtin_object_size(@as(?*const anyopaque, @ptrCast(&ce)), @as(c_int, 0)));
                ce.name = c.zend_string_init_interned.?("Sample", c.strlen("Sample"), @as(c_int, 1) != 0);
                // ce.default_object_handlers = &std_object_handlers;
                ce.info.internal.builtin_functions = @as([*c]const c.zend_function_entry, @ptrCast(@alignCast(&methods[@as(usize, @intCast(0))])));
            }

            self.sample_ce = c.zend_register_internal_class(&ce);
            self.sample_ce.*.unnamed_1.create_object = @ptrCast(&sample_create_obj);

            return c.SUCCESS;
        }
    };
}
