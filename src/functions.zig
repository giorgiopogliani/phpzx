const c = @import("include.zig").c;
const std = @import("std");
const PhpError = @import("errors.zig").PhpError;
const PhpType = @import("types.zig").PhpType;
const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
const helpers = @import("helpers.zig");

/// Php Function Entry wrapper for creating zend_function_entry
pub const PhpFunctionEntry = struct {
    pub fn new(options: struct { name: [*c]const u8, handler: c.zif_handler, arg_info: []const c.zend_internal_arg_info, flags: u32 }) c.zend_function_entry {
        return c.zend_function_entry{
            .fname = options.name,
            .handler = options.handler,
            .arg_info = @as([*c]c.zend_internal_arg_info, @constCast(&options.arg_info[0])),
            .num_args = @as(u32, @intCast(if (options.arg_info.len > 1) options.arg_info.len - 1 else 0)),
            .flags = options.flags,
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

    pub fn from(comptime name: []const u8, comptime Handler: type) c.zend_function_entry {
        const impl = struct {
            fn zif(execute_data: [*c]c.zend_execute_data, return_value: [*c]c.zval) callconv(.c) void {
                const handler_fn = Handler.handle;
                const info_fn = @typeInfo(@TypeOf(handler_fn)).@"fn";
                const params = info_fn.params;

                var diag = PhpDiagnostic{};
                var func = PhpFunctionArg.new(execute_data);
                helpers.check_args_count(&diag, &func, params.len, params.len) catch |err| {
                    diag.report(err);
                    return;
                };

                var args: std.meta.ArgsTuple(@TypeOf(handler_fn)) = undefined;
                inline for (params, 0..) |param, i| {
                    switch (param.type.?) {
                        c.zend_long => {
                            helpers.parse_arg_long(&diag, &func, i + 1, &args[i]) catch |err| {
                                diag.report(err);
                                return;
                            };
                        },
                        c.zend_bool => {
                            helpers.parse_arg_bool(&diag, &func, i + 1, &args[i]) catch |err| {
                                diag.report(err);
                                return;
                            };
                        },
                        c.zend_string => {
                            helpers.parse_arg_string(&diag, &func, i + 1, &args[i]) catch |err| {
                                diag.report(err);
                                return;
                            };
                        },
                        c.zval => {
                            helpers.parse_arg_zval(&diag, &func, i + 1, &args[i]) catch |err| {
                                diag.report(err);
                                return;
                            };
                        },
                        else => unreachable,
                    }
                }

                const result = @call(.auto, handler_fn, args);

                switch (info_fn.return_type.?) {
                    c.zend_long => {
                        helpers.set_zval_long(return_value, result);
                    },
                    c.zend_bool => {
                        helpers.set_zval_bool(return_value, result);
                    },
                    c.zend_string => {
                        helpers.set_zval_string(return_value, result);
                    },
                    c.zval => {
                        helpers.set_zval_zval(return_value, result);
                    },
                    else => unreachable,
                }
            }
        }.zif;

        @export(&impl, .{ .name = "zif_" ++ name });

        return PhpFunctionEntry.new(.{
            //
            .name = @as([*]const u8, @ptrCast(name)),
            .handler = @as(?*const fn () callconv(.c) void, @ptrCast(&impl)),
            .arg_info = &[2]c.zend_internal_arg_info{
                PhpFunctionArgInfo.empty(1),
                PhpFunctionArgInfo.new("value", PhpType.Long),
            },
            .flags = 0,
        });
    }
};

/// Struct to hold information about a PHP function.
pub const PhpFunctionArg = struct {
    args_count: u32 = 0,
    args: [*c]c.zval = null,

    pub fn new(execute_data: [*c]c.zend_execute_data) PhpFunctionArg {
        return .{
            .args = helpers.ZEND_CALL_ARG(execute_data, 0),
            .args_count = c.ZEND_CALL_NUM_ARGS(execute_data),
        };
    }
};

/// Php Function Entry Info wrapper for creating zend_internal_arg_info
pub const PhpFunctionArgInfo = struct {
    pub fn empty(args: usize) c.zend_internal_arg_info {
        return c.zend_internal_arg_info{
            .name = @as([*c]const u8, @ptrFromInt(@as(usize, @bitCast(@as(c_long, @as(c_int, args)))))),
            .type = c.zend_type{
                .ptr = @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
                .type_mask = @as(u32, @bitCast(@as(c_int, 0))),
            },
            .default_value = null,
        };
    }

    pub fn new(arg_name: [*c]const u8, arg_type: PhpType) c.zend_internal_arg_info {
        return c.zend_internal_arg_info{
            .name = arg_name,
            .type = c.zend_type{
                .ptr = @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))),
                .type_mask = @intFromEnum(arg_type),
            },
            .default_value = null,
        };
    }
};
