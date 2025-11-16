const std = @import("std");
const phpzx = @import("phpzx");
const httpz = @import("httpz");
const c = phpzx.c;
const http_router = @import("http_router.zig");

// Import types from router
const HttpRequestObject = http_router.HttpRequestObject;

const allocator = std.heap.c_allocator;

// Global server instance to avoid circular dependency
var global_server_instance: ?*HttpServerObject = null;

// HTTP Server class
const HttpServerObject = struct {
    server: ?httpz.Server(void),
    port: u16,
    running: bool,
    router: ?*http_router.HttpRouterObjectType,
    std: c.zend_object,

    pub fn __construct(self: *HttpServerObject) void {
        self.server = null;
        self.port = 9090;
        self.running = false;
        self.router = null;
        // Don't initialize std field - it's handled by PHP
    }

    pub fn setPort(self: *HttpServerObject, port: c.zend_long) void {
        self.port = @intCast(@max(1, @min(65535, port)));
    }

    pub fn getPort(self: *HttpServerObject) c.zend_long {
        return @intCast(self.port);
    }

    pub fn testMethod(self: *HttpServerObject) void {
        _ = self;
    }

    pub fn setRouter(self: *HttpServerObject, router: *http_router.HttpRouterObjectType) void {
        self.router = router;
        // Increment reference count to prevent GC
        _ = c.GC_ADDREF(&router.std);
    }

    pub fn start(self: *HttpServerObject) c.zend_long {
        if (self.running) return 0; // Already running

        // Set the global instance for the request handler
        global_server_instance = self;

        // Initialize the httpz server with single-threaded configuration
        // PHP is not thread-safe, so we must handle all requests in the same thread
        const server = httpz.Server(void).init(allocator, .{
            .port = self.port,
            .address = "127.0.0.1",
            .workers = .{
                .count = 1,  // Single worker thread
                .max_conn = 128,  // Max pending connections
            },
            .thread_pool = .{
                .count = 1,  // Single thread in pool
                .buffer_size = 32768,  // Buffer per thread
            },
        }, {}) catch |err| {
            std.log.err("Failed to initialize server: {}", .{err});
            global_server_instance = null;
            return 0;
        };

        self.server = server;

        // Set up a catch-all route
        var router = self.server.?.router(.{}) catch |err| {
            std.log.err("Failed to create router: {}", .{err});
            self.server.?.deinit();
            global_server_instance = null;
            return 0;
        };

        // Add a catch-all route for all methods and paths
        router.all("/*", handleRequest, .{});

        self.running = true;

        // Start server in the main thread (blocking)
        // PHP is not thread-safe, so we cannot call closures from other threads
        std.log.info("HTTP server starting on port {d}", .{self.port});
        self.server.?.listen() catch |err| {
            std.log.err("Server listen failed: {}", .{err});
            self.running = false;
            self.server.?.deinit();
            global_server_instance = null;
            return 0;
        };

        return 1; // Success
    }

    pub fn stop(self: *HttpServerObject) void {
        if (!self.running) return;

        self.running = false;

        if (self.server) |*server| {
            server.stop();
            server.deinit();
            self.server = null;
        }

        // Clear global instance
        if (global_server_instance == self) {
            global_server_instance = null;
        }
    }

    pub fn isRunning(self: *HttpServerObject) c.zend_long {
        return if (self.running) 1 else 0;
    }
};

// Request object to pass to PHP handler
const HttpRequest = struct {
    method: []const u8,
    path: []const u8,
    query: []const u8,
    headers: std.StringHashMap([]const u8),
    body: []const u8,

    pub fn getMethod(self: *const HttpRequest) []const u8 {
        return self.method;
    }

    pub fn getPath(self: *const HttpRequest) []const u8 {
        return self.path;
    }

    pub fn getQuery(self: *const HttpRequest) []const u8 {
        return self.query;
    }

    pub fn getBody(self: *const HttpRequest) []const u8 {
        return self.body;
    }
};

// Response object to pass to PHP handler
const HttpResponse = struct {
    status: u16,
    headers: std.StringHashMap([]const u8),
    body: []const u8,

    pub fn setStatus(self: *HttpResponse, status: u16) void {
        self.status = status;
    }

    pub fn setHeader(self: *HttpResponse, name: []const u8, value: []const u8) void {
        self.headers.put(name, value) catch {};
    }

    pub fn setBody(self: *HttpResponse, body: []const u8) void {
        self.body = body;
    }
};

// Private function to handle request (not part of PHP class)
fn callRequestHandler(self: *HttpServerObject, req: *httpz.Request, res: *httpz.Response) !void {
    // httpz is configured for single-threaded mode (workers.count=1, thread_pool.count=1)
    // so all requests are handled on the same thread using non-blocking I/O (epoll/kqueue)
    // This is safe for PHP which is not thread-safe.

    if (self.router == null) {
        res.status = 404;
        res.body = "No router set";
        return;
    }

    // Create HttpRequest and HttpResponse PHP objects
    const request_zval = http_router.HttpRequest.create();
    const request_zobj = c.Z_OBJ(request_zval);
    const request_obj = @as(*http_router.HttpRequestObjectType, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(request_zobj)) - @offsetOf(http_router.HttpRequestObjectType, "std"))));
    request_obj.path = req.url.path;
    request_obj.method = @tagName(req.method);

    const response_zval = http_router.HttpResponse.create();
    const response_zobj = c.Z_OBJ(response_zval);
    const response_obj = @as(*http_router.HttpResponseObjectType, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(response_zobj)) - @offsetOf(http_router.HttpResponseObjectType, "std"))));

    // Call the router's dispatch method
    const result = self.router.?.dispatch(request_obj, response_obj);

    if (result == 1) {
        // Route was found and executed - use the response object
        const response_body_len = response_obj.body_len;

        if (response_body_len > 0) {
            // Allocate memory for the response body
            const response_body = allocator.alloc(u8, response_body_len) catch {
                res.status = 500;
                res.body = "Memory allocation error";
                return;
            };

            @memcpy(response_body, response_obj.body[0..response_body_len]);
            res.status = response_obj.status;
            res.body = response_body;
        } else {
            res.status = response_obj.status;
            res.body = "";
        }
    } else {
        res.status = 404;
        res.body = "Route not found";
    }
}

// Handler function for all HTTP requests
fn handleRequest(req: *httpz.Request, res: *httpz.Response) !void {
    if (global_server_instance) |server_obj| {
        if (server_obj.running) {
            callRequestHandler(server_obj, req, res) catch |err| {
                std.log.err("Request handler error: {}", .{err});
                res.status = 500;
                res.body = "Internal server error";
            };
        } else {
            res.status = 503;
            res.body = "Server not running";
        }
    } else {
        res.status = 500;
        res.body = "Server instance not found";
    }
}

// Export the class and object type
pub const HttpServer = phpzx.PhpClass("HttpServer", HttpServerObject);
pub const HttpServerObjectType = HttpServerObject;
