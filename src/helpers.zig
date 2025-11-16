const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
const PhpFunctionArg = @import("functions.zig").PhpFunctionArg;
const PhpError = @import("errors.zig").PhpError;
const PhpType = @import("types.zig").PhpType;
const types = @import("types.zig");
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
    const success = c.zend_parse_arg_func(func.args + arg_index + 1, fci, fci_cache, true, &error_msg, true);
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
pub inline fn parse_arg_long(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize) PhpError!c.zend_long {
    _ = diag;
    // TODO: check type
    return c.zval_get_long(func.args + arg_index + 1);
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

pub inline fn set_zval_string_from_phpstring(zval: *c.zval, value: types.PhpString) void {
    const zstr = c.zend_string_alloc(value.len, false);
    const val_ptr: [*]u8 = @ptrCast(&zstr.*.val);
    @memcpy(val_ptr[0..value.len], value.ptr[0..value.len]);
    val_ptr[value.len] = 0;
    zstr.*.len = value.len;
    zval.*.value.str = zstr;
    zval.*.u1.type_info = @intFromEnum(PhpType.String);
}

pub inline fn set_zval_double(zval: *c.zval, value: f64) void {
    zval.*.value.dval = value;
    zval.*.u1.type_info = @intFromEnum(PhpType.Double);
}

pub inline fn set_zval_bool(zval: *c.zval, value: bool) void {
    zval.*.u1.type_info = if (value) @intFromEnum(PhpType.True) else @intFromEnum(PhpType.False);
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
pub inline fn parse_arg_string(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize) PhpError!types.PhpString {
    _ = diag;
    const zval_str = func.args + arg_index + 1;

    // Access the zend_string directly from the zval without conversion
    if (zval_str.*.u1.type_info & 0xFF != @intFromEnum(PhpType.String)) {
        return PhpError.ErrorWrongArg;
    }

    const zstr = zval_str.*.value.str;

    return types.PhpString{ .ptr = &zstr.*.val, .len = zstr.*.len };
}

/// Parse string argument as null-terminated slice
pub inline fn parse_arg_string_z(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize) PhpError![:0]const u8 {
    _ = diag;
    const zval_str = func.args + arg_index + 1;

    // Access the zend_string directly from the zval without conversion
    if (zval_str.*.u1.type_info & 0xFF != @intFromEnum(PhpType.String)) {
        return PhpError.ErrorWrongArg;
    }

    const zstr = zval_str.*.value.str;
    const ptr: [*:0]const u8 = @ptrCast(&zstr.*.val);
    return ptr[0..zstr.*.len :0];
}

/// Parse object argument from PHP
pub inline fn parse_arg_object(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize, comptime T: type, out: anytype) PhpError!void {
    _ = diag;
    const std = @import("std");
    const zval_obj = func.args + arg_index + 1;

    // Extract just the type from type_info (mask with 0xFF)
    const type_mask = zval_obj.*.u1.type_info & 0xFF;
    std.debug.print("parse_arg_object: arg_index={d}, type_mask={d}, expected={d}\n", .{ arg_index, type_mask, @intFromEnum(PhpType.Object) });

    if (type_mask != @intFromEnum(PhpType.Object)) {
        std.debug.print("Type mismatch! Returning error\n", .{});
        return PhpError.ErrorInvalidArgumentType;
    }

    const zobj = zval_obj.*.value.obj;
    // Convert zend_object pointer to our object type
    const obj = @as(*T, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(zobj)) - @offsetOf(T, "std"))));
    std.debug.print("Successfully parsed object: {*}\n", .{obj});
    out.* = obj;
}

/// Call a PHP closure/callable
pub inline fn call_closure(fci: *c.zend_fcall_info, fci_cache: *c.zend_fcall_info_cache, retval: [*c]c.zval) PhpError!void {
    fci.*.retval = retval;
    const result = c.zend_call_function(fci, fci_cache);
    if (result != c.SUCCESS) {
        return PhpError.ErrorFailure;
    }
}

pub inline fn create_php_variable(value: anytype, t: PhpType) c.zval {
    const val: c.zval = undefined;
    val.value.obj = value;
    val.u1.type_info = @intFromEnum(t);
}

/// Parse zval argument - returns pointer to the zval
pub inline fn parse_arg_zval(diag: *PhpDiagnostic, func: *const PhpFunctionArg, arg_index: usize, zval_ptr: *[*c]c.zval) PhpError!void {
    _ = diag;
    zval_ptr.* = func.args + arg_index + 1;
}

/// Copy a zval with proper reference counting
/// Implements the ZVAL_COPY macro behavior
pub inline fn zval_copy(dest: *c.zval, src: [*c]const c.zval) void {
    const gc = src.*.value.counted;
    const t = src.*.u1.type_info;
    dest.*.value.counted = gc;
    dest.*.u1.type_info = t;

    // Check if the type is refcounted (Z_TYPE_INFO_REFCOUNTED)
    // Z_TYPE_FLAGS_MASK is 0xff00
    const is_refcounted = (t & 0xff00) != 0;
    if (is_refcounted and gc != null) {
        _ = c.GC_ADDREF(gc);
    }
}
