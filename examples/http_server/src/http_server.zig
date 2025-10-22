const std = @import("std");
const phpzx = @import("phpzx");
const httpz = @import("httpz");
const c = phpzx.c;
const Thread = std.Thread;

const allocator = std.heap.c_allocator;

// Global server instance to avoid circular dependency
var global_server_instance: ?*HttpServerObject = null;

// HTTP Server class
const HttpServerObject = struct {
    server: ?httpz.Server(void),
    port: u16,
    running: bool,
    request_handler_fci: c.zend_fcall_info,
    request_handler_fci_cache: c.zend_fcall_info_cache,
    request_handler_set: bool,
    server_thread: ?Thread,
    std: c.zend_object,

    pub fn __construct(self: *HttpServerObject) void {
        self.server = null;
        self.port = 9090;
        self.running = false;
        self.request_handler_fci = std.mem.zeroes(c.zend_fcall_info);
        self.request_handler_fci_cache = std.mem.zeroes(c.zend_fcall_info_cache);
        self.request_handler_set = false;
        self.server_thread = null;
        // Don't initialize std field - it's handled by PHP
    }

    pub fn setPort(self: *HttpServerObject, port: c.zend_long) void {
        self.port = @intCast(@max(1, @min(65535, port)));
    }

    pub fn getPort(self: *HttpServerObject) c.zend_long {
        return @intCast(self.port);
    }

    pub fn setRequestHandler(self: *HttpServerObject, handler: phpzx.PhpCallable) void {
        self.request_handler_fci = handler.fci;
        self.request_handler_fci_cache = handler.fci_cache;
        self.request_handler_set = true;

        // Increment reference count to prevent GC
        if (self.request_handler_fci.function_name.value.obj) |obj| {
            _ = c.GC_ADDREF(obj);
        }
    }

    pub fn start(self: *HttpServerObject) c.zend_long {
        if (self.running) return 0; // Already running

        // Set the global instance for the request handler
        global_server_instance = self;

        // Initialize the httpz server with void handler
        const server = httpz.Server(void).init(allocator, .{
            .port = self.port,
            .address = "127.0.0.1",
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

        // Start server in a separate thread
        self.server_thread = Thread.spawn(.{}, serverLoop, .{self}) catch |err| {
            std.log.err("Failed to spawn server thread: {}", .{err});
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

        if (self.server_thread) |thread| {
            thread.join();
            self.server_thread = null;
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
    if (!self.request_handler_set) {
        res.status = 404;
        res.body = "No handler set";
        return;
    }
    
    // For now, return a simple response to avoid string creation issues
    // TODO: Implement proper PHP callback integration with safe string handling
    const path = req.url.path;
    
    // Apply bounds checking to path before using it
    if (path.len == 0) {
        res.status = 400;
        res.body = "Bad Request";
        return;
    }
    
    // Use safe string comparisons with bounds checking
    if (std.mem.eql(u8, path, "/")) {
        res.status = 200;
        res.body = "Hello, World!";
    } else if (std.mem.eql(u8, path, "/hello")) {
        res.status = 200;
        res.body = "World!";
    } else {
        res.status = 404;
        res.body = "Not Found";
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

// Server loop function that runs in a separate thread
fn serverLoop(server_obj: *HttpServerObject) void {
    if (server_obj.server) |*server| {
        std.log.info("HTTP server starting on port {d}", .{server_obj.port});
        server.listen() catch |err| {
            std.log.err("Server listen failed: {}", .{err});
            server_obj.running = false;
        };
        std.log.info("HTTP server stopped", .{});
    } else {
        std.log.err("Server instance is null in serverLoop", .{});
        server_obj.running = false;
    }
}

// Export the class and object type
pub const HttpServer = phpzx.PhpClass("HttpServer", HttpServerObject);
pub const HttpServerObjectType = HttpServerObject;
