const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

const allocator = std.heap.c_allocator;

// Route storage structure
const Route = struct {
    path: [256]u8, // Fixed size buffer for path
    path_len: usize,
    handler_fci: c.zend_fcall_info,
    handler_fci_cache: c.zend_fcall_info_cache,
};

// Match a route pattern against a path and extract parameters
// Pattern: /posts/{id}/comments/{comment_id}
// Path: /posts/123/comments/456
// Extracts: id=123, comment_id=456
fn matchRoute(pattern: []const u8, path: []const u8, params: *[8]c.zval, param_count: *u32) bool {
    var pattern_idx: usize = 0;
    var path_idx: usize = 0;
    var current_param: u32 = 0;

    while (pattern_idx < pattern.len) {
        if (pattern[pattern_idx] == '{') {
            // Found parameter start
            pattern_idx += 1;

            // Skip parameter name until '}'
            while (pattern_idx < pattern.len and pattern[pattern_idx] != '}') {
                pattern_idx += 1;
            }

            if (pattern_idx >= pattern.len) return false; // Malformed pattern
            pattern_idx += 1; // Skip '}'

            // Extract the parameter value from path until '/' or end
            const param_start = path_idx;
            while (path_idx < path.len and path[path_idx] != '/') {
                path_idx += 1;
            }

            // Parameter must capture at least one character
            if (param_start == path_idx) return false;

            if (current_param >= 8) return false; // Too many parameters

            // Create a PHP string zval for the parameter
            const param_value = path[param_start..path_idx];

            // Allocate a zend_string and copy the data
            const zstr = c.zend_string_alloc(param_value.len, false);
            // val is a flexible array member [1]u8, get pointer and create slice
            const val_ptr: [*]u8 = @ptrCast(&zstr.*.val);
            @memcpy(val_ptr[0..param_value.len], param_value);
            val_ptr[param_value.len] = 0; // Null terminate
            zstr.*.len = param_value.len;

            params[current_param].value.str = zstr;
            params[current_param].u1.type_info = @intFromEnum(phpzx.PhpType.String);
            current_param += 1;
        } else {
            // Literal character - must match
            if (path_idx >= path.len or pattern[pattern_idx] != path[path_idx]) {
                return false;
            }
            pattern_idx += 1;
            path_idx += 1;
        }
    }

    // Both must be fully consumed
    if (path_idx != path.len) {
        return false;
    }

    param_count.* = current_param;
    return true;
}

// Router class that handles HTTP-style routing
const RouterObject = struct {
    routes: std.ArrayList(Route),
    std: c.zend_object,

    pub fn __construct(self: *RouterObject) void {
        self.*.routes = std.ArrayList(Route).initCapacity(allocator, 4) catch blk: {
            // Fallback to empty list if allocation fails
            break :blk .{
                .items = &[_]Route{},
                .capacity = 0,
            };
        };
    }

    pub fn getRouteCount(self: *RouterObject) c.zend_long {
        return @intCast(self.*.routes.items.len);
    }

    pub fn addRoute(self: *RouterObject, path: phpzx.PhpString, handler: phpzx.PhpCallable) void {
        var route = Route{
            .path = undefined,
            .path_len = 0,
            .handler_fci = handler.fci,
            .handler_fci_cache = handler.fci_cache,
        };

        // Increment reference count on the closure to prevent GC
        if (route.handler_fci.function_name.value.obj) |obj| {
            _ = c.GC_ADDREF(obj);
        }

        // Copy the path string to our buffer
        const copy_len = @min(path.len, 255);
        @memcpy(route.path[0..copy_len], path.ptr[0..copy_len]);
        route.path[copy_len] = 0; // Null terminate
        route.path_len = copy_len;

        self.*.routes.append(allocator, route) catch {
            // TODO: throw PHP exception
            return;
        };
    }

    pub fn dispatch(self: *RouterObject, path: phpzx.PhpString) c.zend_long {
        const path_slice = path.ptr[0..path.len];

        for (self.*.routes.items) |*route| {
            const route_path = route.path[0..route.path_len];

            // Try to match the route (with or without parameters)
            var params: [8]c.zval = undefined; // Support up to 8 parameters
            var param_count: u32 = 0;

            if (matchRoute(route_path, path_slice, &params, &param_count)) {
                // Found matching route - call the handler with params
                var retval: c.zval = undefined;
                var callable = phpzx.PhpCallable{
                    .fci = route.handler_fci,
                    .fci_cache = route.handler_fci_cache,
                };

                // Initialize the return value
                retval.u1.type_info = @intFromEnum(phpzx.PhpType.Null);

                // Set up parameters for the closure call
                callable.fci.retval = &retval;
                callable.fci.param_count = param_count;
                callable.fci.params = if (param_count > 0) &params else null;

                const result = c.zend_call_function(&callable.fci, &callable.fci_cache);
                if (result != c.SUCCESS) {
                    return 0;
                }

                return 1; // Success
            }
        }

        return 0; // Route not found
    }
};

// Register the Router class
const Router = phpzx.PhpClass("Router", RouterObject);

// Module startup - register the Router class
pub export fn zm_startup_router(arg_type: c_int, arg_module_number: c_int) callconv(.c) c.zend_result {
    _ = arg_type;
    _ = arg_module_number;
    return Router.register();
}

var module = phpzx.PhpModuleBuilder
    .new("zigrouter")
    .minit(zm_startup_router)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}
