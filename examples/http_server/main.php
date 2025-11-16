<?php

// Load the extension if not already loaded
if (!extension_loaded('httpserver')) {
    echo "Extension 'httpserver' not loaded. Please run with:\n";
    echo "php -d extension=zig-out/lib/libhttpserver.dylib main.php\n";
    exit(1);
}

echo "=== HTTP Server Example ===\n\n";

// Create a new HTTP server instance
$server = new HttpServer();
$router = new HttpRouter();

$router->addRoute(
    '/', function ($request, $response) {
        $response->setBody('Hello, World!');
        $response->setStatus(200);
    }
);


echo "Testing testMethod()...\n";
$server->testMethod();

echo "Testing setRouter()...\n";
$server->setRouter($router);

$result = $server->start();

if ($result && $server->isRunning()) {
    echo "HTTP server running on port " . $server->getPort() . "..." . PHP_EOL;

    echo "You can now test the server:\n";
    echo "curl http://localhost:" . $server->getPort() . "/\n";
    echo "curl http://localhost:" . $server->getPort() . "/hello\n";
    echo "\nPress Ctrl+C to stop the server\n\n";

    // Keep the server running for a limited time for testing
    while ($server->isRunning()) {
        sleep(1);
    }

    echo "Stopping server...\n";
    $server->stop();
} else {
    echo "Failed to start server!" . PHP_EOL;
}
