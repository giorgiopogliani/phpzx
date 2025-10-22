const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
const PhpFunctionArg = @import("functions.zig").PhpFunctionArg;
const PhpError = @import("errors.zig").PhpError;
const PhpType = @import("types.zig").PhpType;
const c = @import("include.zig").c;

/// Parse variadic arguments into a pointer to an array of zvals and the number of elements.
pub inline fn parse_arg_variadic(diag: *PhpDiagnostic, func: *PhpFunctionArg, arg_index: usize, dest: *[*c]c.zval, dest_num: *c_int) !void {
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
pub inline fn parse_arg_closure(diag: *PhpDiagnostic, func: *PhpFunctionArg, arg_index: usize, fci: *c.zend_fcall_info, fci_cache: *c.zend_fcall_info_cache) PhpError!void {
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
pub inline fn parse_arg_long(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize, long: *c.zend_long) PhpError!void {
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
pub inline fn check_args_count(diag: *PhpDiagnostic, func: *const PhpFunctionArg, comptime min_num_args: u32, comptime max_num_args: u32) !void {
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

pub inline fn set_zval_zval(zval: *c.zval, value: *c.zval) void {
    zval.*.value.zval = value;
    zval.*.u1.type_info = @intFromEnum(PhpType.Array);
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

/// Parse string argument
pub inline fn parse_arg_string(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize, str: *[*c]u8, str_len: *usize) PhpError!void {
    _ = diag;
    const zval_str = func.args + arg_index;
    
    // Access the zend_string directly from the zval without conversion
    if (zval_str.*.u1.type_info & 0xFF != @intFromEnum(PhpType.String)) {
        return PhpError.ErrorWrongArg;
    }
    
    const zstr = zval_str.*.value.str;
    // Get the string data pointer - zend_string has the data right after the struct
    str.* = @ptrCast(&zstr.*.val);
    str_len.* = zstr.*.len;
}

/// Call a PHP closure/callable
pub inline fn call_closure(fci: *c.zend_fcall_info, fci_cache: *c.zend_fcall_info_cache, retval: [*c]c.zval) PhpError!void {
    fci.*.retval = retval;
    const result = c.zend_call_function(fci, fci_cache);
    if (result != c.SUCCESS) {
        return PhpError.ErrorFailure;
    }
}
