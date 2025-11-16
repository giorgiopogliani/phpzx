const c = @import("include.zig").c;
const std = @import("std");
const PhpFunctionArgInfo = @import("functions.zig").PhpFunctionArgInfo;
const PhpFunctionEntry = @import("functions.zig").PhpFunctionEntry;
const PhpType = @import("types.zig").PhpType;
const PhpInt = @import("types.zig").PhpInt;
const PhpError = @import("errors.zig").PhpError;

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
    // std.debug.print("Allocating object\n", .{});
    const obj = @as(*T, @ptrCast(@alignCast(c.zend_object_alloc(@sizeOf(T), ce))));
    // std.debug.print("Initializing object\n", .{});
    c.zend_object_std_init(&obj.*.std, ce);
    // std.debug.print("Initializing object properties\n", .{});
    c.object_properties_init(&obj.*.std, ce);
    // std.debug.print("Initializing object handlers\n", .{});
    obj.*.std.handlers = handlers;
    // std.debug.print("Returning object\n", .{});
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
            // std.debug.print("Creating object for class {s}\n", .{class_name});
            const obj = createObjectHandler(T, ce_param, &handlers);
            // std.debug.print("Returning object\n", .{});
            return obj;
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

        /// Create a new instance of this class from Zig
        pub fn create() c.zval {
          var zval: c.zval = undefined;
          _ = c.object_init_ex(&zval, ce);
          return zval;
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
                        inline for (params[1..], 0..) |param, i| {
                            const param_type = param.type.?;

                            // Check if it's a pointer to an object type
                            const param_info = @typeInfo(param_type);
                            if (param_info == .pointer) {
                                const child_type = param_info.pointer.child;
                                if (@typeInfo(child_type) == .@"struct" and @hasField(child_type, "std")) {
                                    // Parse object parameter
                                    helpers.parse_arg_object(&diag, &func, i, child_type, &args[i + 1]) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                    continue;
                                }
                            }

                            switch (param_type) {
                                types.PhpInt => {
                                    args[i + 1] = helpers.parse_arg_long(&diag, &func, i) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                types.PhpCallable => {
                                    // Parse callable into the PhpCallable struct
                                    helpers.parse_arg_closure(&diag, &func, i, &args[i + 1].fci, &args[i + 1].fci_cache) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                types.PhpString => {
                                    // Parse string into the PhpString struct
                                    args[i + 1] = helpers.parse_arg_string(&diag, &func, i) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                },
                                types.PhpArray => {
                                    // Parse array into the PhpArray struct
                                    var zval_ptr: [*c]c.zval = undefined;
                                    helpers.parse_arg_zval(&diag, &func, i, &zval_ptr) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                    helpers.check_arg_type(&diag, i + 1, zval_ptr, types.PhpType.Array) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                    args[i + 1] = types.PhpArray.from(zval_ptr);
                                },
                                types.PhpValue => {
                                    // Parse any value into the PhpValue struct
                                    var zval_ptr: [*c]c.zval = undefined;
                                    helpers.parse_arg_zval(&diag, &func, i, &zval_ptr) catch |err| {
                                        diag.report(err);
                                        return;
                                    };
                                    // args[i + 1] = types.PhpValue.init(zval_ptr);
                                    args[i + 1] = types.PhpValue.parse(&diag, &func, i, &zval_ptr);
                                },
                                c.zval => {
                                    // Pass zval directly
                                    args[i + 1] = (func.args + i + 1).*;
                                },
                                [*c]c.zval => {
                                    // Pass zval pointer directly
                                    args[i + 1] = func.args + i + 1;
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

    // Handle pointer types
    const type_info = @typeInfo(T);
    if (type_info == .pointer) {
        // Check if it's a struct with a 'std' field (PHP object)
        const child_type = type_info.pointer.child;
        if (@typeInfo(child_type) == .@"struct") {
            if (@hasField(child_type, "std")) {
                return PhpType.Object;
            }
        }
    }

    return switch (T) {
        i64, i32 => PhpType.Long,
        bool => PhpType.True,
        f64, f32 => PhpType.Double,
        c.zend_string, [*c]c.zend_string => PhpType.String,
        [*c]c.zval => PhpType.Mixed,
        c.zval => PhpType.Mixed,
        types.PhpCallable => PhpType.Callable,
        types.PhpString => PhpType.String,
        types.PhpArray => PhpType.Array,
        types.PhpValue => PhpType.Mixed,
        [:0]const u8, []const u8 => PhpType.String,
        else => @compileError("Unsupported PHP type mapping for: " ++ @typeName(T)),
    };
}

fn setReturnValue(return_value: [*c]c.zval, result: anytype, comptime ret_type: ?type) void {
    if (ret_type) |rt| {
        if (rt == void) {
            return;
        }

        // Handle pointer types (like object pointers)
        const type_info = @typeInfo(rt);
        if (type_info == .pointer) {
            const child_type = type_info.pointer.child;
            if (@typeInfo(child_type) == .@"struct" and @hasField(child_type, "std")) {
                // This is a PHP object pointer - wrap it in a zval
                return_value.*.value.obj = @ptrCast(&result.*.std);
                return_value.*.u1.type_info = @intFromEnum(PhpType.Object);
                return;
            }
        }

        switch (rt) {
            c.zend_long => {
                return_value.*.value.lval = result;
                return_value.*.u1.type_info = @intFromEnum(PhpType.Long);
            },
            c.zval => {
                return_value.* = result;
            },
            else => {},
        }
    }
}
