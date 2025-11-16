const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

// Import our separate modules
const http_server = @import("http_server.zig");
const http_router = @import("http_router.zig");

// Re-export the classes for easier access
pub const HttpServer = http_server.HttpServer;
pub const HttpRouter = http_router.HttpRouter;
pub const HttpRequest = http_router.HttpRequest;
pub const HttpResponse = http_router.HttpResponse;

// Module startup - register all classes (FOR EXTENSION MODE)
pub export fn zm_startup_httpserver(arg_type: c_int, arg_module_number: c_int) callconv(.c) c.zend_result {
    _ = arg_type;
    _ = arg_module_number;

    // Register HttpServer class
    const server_result = HttpServer.register();
    if (server_result != c.SUCCESS) {
        return server_result;
    }

    // Register HttpRouter class
    const router_result = HttpRouter.register();
    if (router_result != c.SUCCESS) {
        return router_result;
    }

    // Register HttpRequest class
    const request_result = HttpRequest.register();
    if (request_result != c.SUCCESS) {
        return request_result;
    }

    // Register HttpResponse class
    const response_result = HttpResponse.register();
    if (response_result != c.SUCCESS) {
        return response_result;
    }

    return c.SUCCESS;
}

// Module shutdown - cleanup if needed
pub export fn zm_shutdown_httpserver(arg_type: c_int, arg_module_number: c_int) callconv(.c) c.zend_result {
    _ = arg_type;
    _ = arg_module_number;
    return c.SUCCESS;
}

// Build the module with startup
var module = phpzx.PhpModuleBuilder
    .new("httpserver")
    .minit(zm_startup_httpserver)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}
