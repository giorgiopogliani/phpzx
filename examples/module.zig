const std = @import("std");
const php = @import("php.zig");
const base = @import("phpzx");

/// Main extension function
pub export fn zif_num_double(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) void {
    var diag = base.PhpDiagnostic{};
    var func = base.PhpFunction.new(execute_data);

    base.check_args_count(&diag, &func, 1, 1) catch |err| {
        diag.report(err);
        return;
    };

    var long: php.zend_long = undefined;
    base.parse_arg_long(&diag, &func, 1, &long) catch |err| {
        diag.report(err);
        return;
    };

    long = long * 2;

    base.set_zval_long(return_value, long);
}
