const std = @import("std");
const php = @import("phpzx").c;
const phpzx = @import("phpzx");

const PhpDiagnostic = phpzx.PhpDiagnostic;
const PhpFunction = phpzx.PhpFunction;

/// Main extension function
pub export fn zif_num_double(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) void {
    var diag = PhpDiagnostic{};
    var func = PhpFunction.new(execute_data);

    phpzx.check_args_count(&diag, &func, 1, 1) catch |err| {
        diag.report(err);
        return;
    };

    var long: php.zend_long = undefined;
    phpzx.parse_arg_long(&diag, &func, 1, &long) catch |err| {
        diag.report(err);
        return;
    };

    long = long * 2;

    phpzx.set_zval_long(return_value, long);
}
