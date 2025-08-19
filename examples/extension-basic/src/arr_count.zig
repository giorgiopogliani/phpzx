const std = @import("std");
const php = @import("phpzx");

pub inline fn parse_arg_array(diag: *php.PhpDiagnostic, func: *php.PhpFunction, index: u32, array: *[*c]php.zval, types: []const php.PhpType) !void {
    const arg = func.args + index;
    const arg_type: php.PhpType = @enumFromInt(php.zval_get_type(arg));

    for (types) |t| {
      if (arg_type == t) {
        array.* = arg;
        return;
      }
    }

    diag.num_arg = index;
    diag.args = arg;
    diag.expected_type = php.Z_EXPECTED_ITERABLE;

    return php.PhpError.ErrorUnexpectedType;
}

/// Main extension function
pub export fn zif_arr_count(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) void {
    var diag = php.PhpDiagnostic{};
    var func = php.PhpFunction.new(execute_data);

    php.check_args_count(&diag, &func, 1, 1) catch |err| {
        diag.report(err);
        return;
    };

    var array: [*c]php.zval = undefined;
    parse_arg_array(&diag, &func, 1, &array, &.{ php.PhpType.Array, php.PhpType.Object }) catch |err| {
        diag.report(err);
        return;
    };

    php.set_zval_long(return_value, php.zend_hash_num_elements(php.Z_ARRVAL_P(array)));
}
