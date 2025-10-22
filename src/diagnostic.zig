pub const PhpDiagnostic = @This();

const c = @import("include.zig").c;
const PhpError = @import("errors.zig").PhpError;

/// Optional diagnostics used for reporting useful errors
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
