const c = @import("include.zig").c;
const std = @import("std");
const PhpFunctionArgInfo = @import("functions.zig").PhpFunctionArgInfo;
const PhpFunctionEntry = @import("functions.zig").PhpFunctionEntry;
const PhpType = @import("types.zig").PhpType;

/// Helper to get object from execute_data This pointer
pub inline fn getThisObject(comptime T: type, execute_data: [*c]c.zend_execute_data) *T {
    const zobj: *c.zend_object = @ptrCast(@alignCast((&execute_data.*.This).*.value.ptr));
    return @ptrCast(@alignCast(@as([*c]u8, @ptrCast(zobj)) - @offsetOf(T, "std")));
}

/// Helper to initialize a class entry
pub inline fn initClassEntry(
    ce: *c.zend_class_entry,
    name: [:0]const u8,
    methods: [*c]const c.zend_function_entry,
) void {
    _ = c.__builtin___memset_chk(
        @as(?*anyopaque, @ptrCast(ce)),
        @as(c_int, 0),
        @sizeOf(c.zend_class_entry),
        c.__builtin_object_size(@as(?*const anyopaque, @ptrCast(ce)), @as(c_int, 0)),
    );

    ce.*.name = c.zend_string_init_interned.?(
        name.ptr,
        name.len,
        @as(c_int, 1) != 0,
    );
    ce.*.default_object_handlers = &c.std_object_handlers;
    ce.*.info.internal.builtin_functions = methods;
}

/// Helper to register internal class
pub inline fn registerClass(
    ce: *c.zend_class_entry,
    create_object_handler: *const fn ([*c]c.zend_class_entry) callconv(.c) [*c]c.zend_object,
) *c.zend_class_entry {
    const registered_ce = c.zend_register_internal_class(ce);
    registered_ce.*.unnamed_1.create_object = create_object_handler;
    return registered_ce;
}

/// Helper to copy standard object handlers
pub inline fn copyStdHandlers(handlers: *c.zend_object_handlers) void {
    _ = c.__builtin___memcpy_chk(
        @as(?*anyopaque, @ptrCast(handlers)),
        @as(?*const anyopaque, @ptrCast(&c.std_object_handlers)),
        @sizeOf(c.zend_object_handlers),
        c.__builtin_object_size(@as(?*const anyopaque, @ptrCast(handlers)), @as(c_int, 0)),
    );
}

/// Generic create object handler
pub fn createObjectHandler(
    comptime T: type,
    ce: [*c]c.zend_class_entry,
    handlers: *c.zend_object_handlers,
) [*c]c.zend_object {
    const obj = @as(*T, @ptrCast(@alignCast(c.zend_object_alloc(@sizeOf(T), ce))));
    c.zend_object_std_init(&obj.*.std, ce);
    c.object_properties_init(&obj.*.std, ce);
    obj.*.std.handlers = handlers;
    return &obj.*.std;
}

/// Class registration info that gets generated at comptime
pub fn PhpClass(comptime class_name: [:0]const u8, comptime T: type) type {
    return struct {
        const Self = @This();

        // Storage for class entry and handlers
        var ce: *c.zend_class_entry = undefined;
        var handlers: c.zend_object_handlers = undefined;

        // Auto-generated create object handler
        fn createObject(ce_param: [*c]c.zend_class_entry) callconv(.c) [*c]c.zend_object {
            return createObjectHandler(T, ce_param, &handlers);
        }

        // Auto-generated method entries
        const method_entries = generateMethods();

        /// Register this class during module initialization
        pub fn register() c.zend_result {
            var ce_local: c.zend_class_entry = undefined;
            initClassEntry(&ce_local, class_name, &method_entries);
            ce = registerClass(&ce_local, &createObject);
            copyStdHandlers(&handlers);
            return c.SUCCESS;
        }

        fn generateMethods() [countMethodsInType() + 1]c.zend_function_entry {
            const decls = @typeInfo(T).@"struct".decls;
            comptime var method_count = 0;

            // Count valid methods (skip fields like 'value', 'std')
            inline for (decls) |decl| {
                if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
                    method_count += 1;
                }
            }

            var method_array: [method_count + 1]c.zend_function_entry = undefined;
            comptime var index = 0;

            inline for (decls) |decl| {
                if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
                    method_array[index] = generateMethod(T, decl.name, @field(T, decl.name));
                    index += 1;
                }
            }

            method_array[method_count] = PhpFunctionEntry.empty();
            return method_array;
        }

        fn countMethodsInType() comptime_int {
            const decls = @typeInfo(T).@"struct".decls;
            comptime var count = 0;
            inline for (decls) |decl| {
                if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
                    count += 1;
                }
            }
            return count;
        }
    };
}

/// Helper to register multiple classes at once
pub fn registerClasses(comptime classes: anytype) c.zend_result {
    inline for (classes) |Class| {
        const result = Class.register();
        if (result != c.SUCCESS) {
            return result;
        }
    }
    return c.SUCCESS;
}

/// Old API for backward compatibility - generates just the method entries
pub fn PhpClassBuilder(comptime T: type) type {
    return struct {
        pub fn methods() [countMethods(T) + 1]c.zend_function_entry {
            const decls = @typeInfo(T).@"struct".decls;
            comptime var method_count = 0;

            inline for (decls) |decl| {
                if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
                    method_count += 1;
                }
            }

            var method_array: [method_count + 1]c.zend_function_entry = undefined;
            comptime var index = 0;

            inline for (decls) |decl| {
                if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
                    method_array[index] = generateMethod(T, decl.name, @field(T, decl.name));
                    index += 1;
                }
            }

            method_array[method_count] = PhpFunctionEntry.empty();
            return method_array;
        }
    };
}

fn countMethods(comptime T: type) comptime_int {
    const decls = @typeInfo(T).@"struct".decls;
    comptime var count = 0;
    inline for (decls) |decl| {
        if (@typeInfo(@TypeOf(@field(T, decl.name))) == .@"fn") {
            count += 1;
        }
    }
    return count;
}

fn generateMethod(comptime T: type, comptime name: []const u8, comptime method: anytype) c.zend_function_entry {
            const helpers = @import("helpers.zig");
            const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
            const PhpFunctionArg = @import("functions.zig").PhpFunctionArg;
            const types = @import("types.zig");

            const info = @typeInfo(@TypeOf(method)).@"fn";
            const params = info.params;

            // Skip first parameter (self: *T)
            const php_param_count = if (params.len > 1) params.len - 1 else 0;

            // Generate arg info at comptime as a constant
            const arg_info = comptime blk: {
                var info_array: [php_param_count + 1]c.zend_internal_arg_info = undefined;
                info_array[0] = PhpFunctionArgInfo.empty(php_param_count);

                // Generate arg_info for each parameter (skip first which is self)
                if (params.len > 1) {
                    for (params[1..], 0..) |param, i| {
                        const param_type = param.type orelse @compileError("Parameter must have a type");
                        const php_type = mapZigTypeToPhp(param_type);
                        // For now, use generic name - could be improved with parameter names
                        const param_name = std.fmt.comptimePrint("arg{d}", .{i});
                        info_array[i + 1] = PhpFunctionArgInfo.new(param_name.ptr, php_type);
                    }
                }

                break :blk info_array;
            };

            // Generate wrapper function
            const Wrapper = struct {
                fn call(execute_data: [*c]c.zend_execute_data, return_value: [*c]c.zval) callconv(.c) void {
                    const obj = getThisObject(T, execute_data);

                    if (php_param_count == 0) {
                        // No parameters besides self
                        const result = @call(.auto, method, .{obj});
                        setReturnValue(return_value, result, info.return_type);
                    } else {
                        // Parse arguments
                        var diag = PhpDiagnostic{};
                        var func = PhpFunctionArg.new(execute_data);

                        helpers.check_args_count(&diag, &func, php_param_count, php_param_count) catch |err| {
                            diag.report(err);
                            return;
                        };

                        // Build arguments tuple
                        var args: std.meta.ArgsTuple(@TypeOf(method)) = undefined;
                        args[0] = obj; // First argument is always self

                        // Parse remaining arguments
                        inline for (params[1..], 1..) |param, i| {
                            const param_type = param.type.?;
                            
                            switch (param_type) {
                                c.zend_long => {
                                    helpers.parse_arg_long(&diag, &func, i, &args[i]) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                types.PhpCallable => {
                                    // Parse callable into the PhpCallable struct
                                    helpers.parse_arg_closure(&diag, &func, i, &args[i].fci, &args[i].fci_cache) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                types.PhpString => {
                                    // Parse string into the PhpString struct
                                    helpers.parse_arg_string(&diag, &func, i, &args[i].ptr, &args[i].len) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                else => @compileError("Unsupported parameter type: " ++ @typeName(param_type)),
                            }
                        }

                        // Call method with parsed arguments
                        const result = @call(.auto, method, args);
                        setReturnValue(return_value, result, info.return_type);
                    }
                }
            };

            const export_name = "zim_" ++ @typeName(T) ++ "_" ++ name;
            @export(&Wrapper.call, .{ .name = export_name });

            // Determine flags
            const flags = if (std.mem.eql(u8, name, "__construct"))
                c.ZEND_ACC_PUBLIC | c.ZEND_ACC_CTOR
            else
                c.ZEND_ACC_PUBLIC;

            return PhpFunctionEntry.new(.{
                .name = @ptrCast(name.ptr),
                .handler = @ptrCast(&Wrapper.call),
                .arg_info = &arg_info,
                .flags = flags,
            });
}

fn mapZigTypeToPhp(comptime T: type) PhpType {
    const types = @import("types.zig");
    return switch (T) {
        c.zend_long => PhpType.Long,
        c.zend_bool => PhpType.True, // Bool type
        c.zend_string, [*c]c.zend_string => PhpType.String,
        [*c]c.zval => PhpType.Mixed,
        types.PhpCallable => PhpType.Callable,
        types.PhpString => PhpType.String,
        else => @compileError("Unsupported PHP type mapping for: " ++ @typeName(T)),
    };
}

fn setReturnValue(return_value: [*c]c.zval, result: anytype, comptime ret_type: ?type) void {
    if (ret_type) |rt| {
        if (rt == void) {
            return;
        }
        switch (rt) {
            c.zend_long => {
                return_value.*.value.lval = result;
                return_value.*.u1.type_info = @intFromEnum(PhpType.Long);
            },
            else => {},
        }
    }
}
