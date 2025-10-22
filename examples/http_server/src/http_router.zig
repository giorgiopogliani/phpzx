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

// Request object for router dispatch
const HttpRequestObject = struct {
    path: []const u8,
    method: []const u8,
    std: c.zend_object,

    pub fn __construct(self: *HttpRequestObject) void {
        self.path = "";
        self.method = "GET";
        // Don't initialize std field - it's handled by PHP
    }

    pub fn getPath(self: *HttpRequestObject) phpzx.PhpString {
        return phpzx.PhpString{
            .ptr = @constCast(self.path.ptr),
            .len = self.path.len,
        };
    }

    pub fn getMethod(self: *HttpRequestObject) phpzx.PhpString {
        return phpzx.PhpString{
            .ptr = @constCast(self.method.ptr),
            .len = self.method.len,
        };
    }

    pub fn setPath(self: *HttpRequestObject, path: phpzx.PhpString) void {
        // For simplicity, we'll just store the pointer (assumes PHP string stays alive)
        self.path = path.ptr[0..path.len];
    }

    pub fn setMethod(self: *HttpRequestObject, method: phpzx.PhpString) void {
        self.method = method.ptr[0..method.len];
    }
};

// Response object for router dispatch
const HttpResponseObject = struct {
    body: []const u8,
    status: u16,
    std: c.zend_object,

    pub fn __construct(self: *HttpResponseObject) void {
        self.body = "";
        self.status = 200;
        // Don't initialize std field - it's handled by PHP
    }

    pub fn getBody(self: *HttpResponseObject) phpzx.PhpString {
        return phpzx.PhpString{
            .ptr = @constCast(self.body.ptr),
            .len = self.body.len,
        };
    }

    pub fn getStatus(self: *HttpResponseObject) c.zend_long {
        return @intCast(self.status);
    }

    pub fn setBody(self: *HttpResponseObject, body: phpzx.PhpString) void {
        self.body = body.ptr[0..body.len];
    }

    pub fn setStatus(self: *HttpResponseObject, status: c.zend_long) void {
        self.status = @intCast(@max(100, @min(599, status)));
    }
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
const HttpRouterObject = struct {
    routes: std.ArrayList(Route),
    std: c.zend_object,

    pub fn __construct(self: *HttpRouterObject) void {
        self.*.routes = std.ArrayList(Route){};
    }

    pub fn getRouteCount(self: *HttpRouterObject) c.zend_long {
        return @intCast(self.*.routes.items.len);
    }

    pub fn addRoute(self: *HttpRouterObject, path: phpzx.PhpString, handler: phpzx.PhpCallable) void {
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

    pub fn dispatch(self: *HttpRouterObject, path: phpzx.PhpString) phpzx.PhpString {
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
                    // Return empty string on error
                    return phpzx.PhpString{
                        .ptr = @constCast(""),
                        .len = 0,
                    };
                }

                // Convert the return value to a string and return it
                if (retval.u1.type_info == @intFromEnum(phpzx.PhpType.String)) {
                    const str = retval.value.str;
                    return phpzx.PhpString{
                        .ptr = @ptrCast(&str.*.val),
                        .len = str.*.len,
                    };
                } else {
                    // Convert other types to string representation
                    // For now, return empty string
                    return phpzx.PhpString{
                        .ptr = @constCast(""),
                        .len = 0,
                    };
                }
            }
        }

        // Route not found - return empty string
        return phpzx.PhpString{
            .ptr = @constCast(""),
            .len = 0,
        };
    }
};

// Export the class and object types
pub const HttpRouter = phpzx.PhpClass("HttpRouter", HttpRouterObject);
pub const HttpRequest = phpzx.PhpClass("HttpRequest", HttpRequestObject);
pub const HttpResponse = phpzx.PhpClass("HttpResponse", HttpResponseObject);
pub const HttpRouterObjectType = HttpRouterObject;
pub const HttpRequestObjectType = HttpRequestObject;
pub const HttpResponseObjectType = HttpResponseObject;