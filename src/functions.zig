const c = @import("include.zig").c;
const std = @import("std");
const PhpError = @import("errors.zig").PhpError;
const PhpType = @import("types.zig").PhpType;
const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
const helpers = @import("helpers.zig");
const types = @import("types.zig");

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
                    const ParamType = param.type.?;
                    if (ParamType == types.PhpInt or ParamType == i64 or ParamType == c.zend_long) {
                        args[i] = helpers.parse_arg_long(&diag, &func, i) catch |err| {
                            diag.report(err);
                            return;
                        };
                    } else if (ParamType == i32) {
                        const long_val = helpers.parse_arg_long(&diag, &func, i) catch |err| {
                            diag.report(err);
                            return;
                        };
                        args[i] = @intCast(long_val);
                    } else if (ParamType == [:0]const u8) {
                        args[i] = helpers.parse_arg_string_z(&diag, &func, i) catch |err| {
                            diag.report(err);
                            return;
                        };
                    } else if (ParamType == types.PhpString or ParamType == []const u8) {
                        args[i] = helpers.parse_arg_string(&diag, &func, i) catch |err| {
                            diag.report(err);
                            return;
                        };
                    } else if (ParamType == types.PhpArray) {
                        const zval_arg = func.args + i + 1;
                        args[i] = types.PhpArray.from(zval_arg);
                    } else if (ParamType == bool) {
                        const zval_arg = func.args + i + 1;
                        args[i] = c.zval_is_true(zval_arg);
                    } else if (ParamType == f64) {
                        const zval_arg = func.args + i + 1;
                        args[i] = c.zval_get_double(zval_arg);
                    } else if (ParamType == f32) {
                        const zval_arg = func.args + i + 1;
                        args[i] = @floatCast(c.zval_get_double(zval_arg));
                    } else if (@typeInfo(ParamType) == .@"enum") {
                        const long_val = helpers.parse_arg_long(&diag, &func, i) catch |err| {
                            diag.report(err);
                            return;
                        };
                        args[i] = @enumFromInt(long_val);
                    } else if (@typeInfo(ParamType) == .@"struct") {
                        if (@hasDecl(ParamType, "fromPhp")) {
                            args[i] = ParamType.fromPhp(&diag, &func, i) catch |err| {
                                diag.report(err);
                                return;
                            };
                        } else {
                            // Try array conversion for structs
                            const zval_arg = func.args + i + 1;
                            const type_mask = zval_arg.*.u1.type_info & 0xFF;
                            
                            if (type_mask == @intFromEnum(PhpType.Array)) {
                                // Parse array into struct fields
                                const arr_table = c.Z_ARRVAL_P(zval_arg);
                                var result: ParamType = undefined;
                                const fields = @typeInfo(ParamType).@"struct".fields;
                                var idx: u32 = 0;
                                inline for (fields) |field| {
                                    if (idx >= arr_table.*.nNumOfElements) break;
                                    const elem = arr_table.*.unnamed_0.arPacked + idx;
                                    
                                    if (field.type == f32) {
                                        @field(result, field.name) = @floatCast(c.zval_get_double(elem));
                                    } else if (field.type == f64) {
                                        @field(result, field.name) = c.zval_get_double(elem);
                                    } else if (field.type == i32) {
                                        @field(result, field.name) = @intCast(c.zval_get_long(elem));
                                    } else if (field.type == i64 or field.type == c.zend_long) {
                                        @field(result, field.name) = c.zval_get_long(elem);
                                    } else if (field.type == u8) {
                                        @field(result, field.name) = @intCast(c.zval_get_long(elem));
                                    } else {
                                        @compileError("Unsupported field type in struct: " ++ @typeName(field.type));
                                    }
                                    idx += 1;
                                }
                                args[i] = result;
                            } else {
                                // Fallback to integer bitcast
                                const long_val = c.zval_get_long(zval_arg);
                                const size = @sizeOf(ParamType);
                                if (size == 8) {
                                    args[i] = @bitCast(@as(u64, @bitCast(long_val)));
                                } else if (size == 4) {
                                    const truncated: u32 = @truncate(@as(u64, @bitCast(long_val)));
                                    args[i] = @bitCast(truncated);
                                } else {
                                    @compileError("Unsupported struct size for automatic conversion: " ++ @typeName(ParamType));
                                }
                            }
                        }
                    } else {
                        @compileError("Unsupported parameter type: " ++ @typeName(ParamType));
                    }
                }

                const result = @call(.auto, handler_fn, args);

                const ReturnType = info_fn.return_type.?;
                if (ReturnType == void) {
                    // No return value
                } else if (ReturnType == types.PhpInt or ReturnType == i64 or ReturnType == c.zend_long) {
                    helpers.set_zval_long(return_value, result);
                } else if (ReturnType == i32) {
                    helpers.set_zval_long(return_value, @as(c.zend_long, result));
                } else if (ReturnType == types.PhpString) {
                    helpers.set_zval_string_from_phpstring(return_value, result);
                } else if (ReturnType == types.PhpArray) {
                    return_value.*.value.arr = result.table;
                    return_value.*.u1.type_info = @intFromEnum(PhpType.Array);
                } else if (ReturnType == f64) {
                    helpers.set_zval_double(return_value, result);
                } else if (ReturnType == bool or ReturnType == c.zend_bool) {
                    helpers.set_zval_bool(return_value, result);
                } else if (ReturnType == c.zend_string) {
                    helpers.set_zval_string(return_value, result);
                } else if (ReturnType == c.zval) {
                    helpers.set_zval_zval(return_value, result);
                } else if (@typeInfo(ReturnType) == .@"enum") {
                    helpers.set_zval_long(return_value, @intFromEnum(result));
                } else if (@typeInfo(ReturnType) == .@"struct") {
                    if (@hasDecl(ReturnType, "toPhp")) {
                        result.toPhp(return_value);
                    } else {
                        // Convert struct to array
                        const fields = @typeInfo(ReturnType).@"struct".fields;
                        var php_arr = types.PhpArray.new(return_value, fields.len);
                        
                        inline for (fields) |field| {
                            var elem: c.zval = undefined;
                            const field_value = @field(result, field.name);
                            
                            if (field.type == f32 or field.type == f64) {
                                helpers.set_zval_double(&elem, @floatCast(field_value));
                            } else if (field.type == i32 or field.type == i64 or field.type == c.zend_long) {
                                helpers.set_zval_long(&elem, @intCast(field_value));
                            } else if (field.type == u8) {
                                helpers.set_zval_long(&elem, @intCast(field_value));
                            } else if (field.type == bool) {
                                helpers.set_zval_bool(&elem, field_value);
                            } else {
                                @compileError("Unsupported field type in return struct: " ++ @typeName(field.type));
                            }
                            
                            php_arr.fill(elem);
                        }
                    }
                } else {
                    @compileError("Unsupported return type: " ++ @typeName(ReturnType));
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
