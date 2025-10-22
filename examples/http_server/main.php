<?php

// Load the extension if not already loaded
if (!extension_loaded('httpserver')) {
    echo "Extension 'httpserver' not loaded. Please run with:\n";
    echo "php -d extension=zig-out/lib/libhttpserver.dylib main.php\n";
    exit(1);
}

require __DIR__ . '/vendor/autoload.php';

echo "=== HTTP Server Example ===\n\n";

// Create a new HTTP server instance
$server = new HttpServer();
$router = new HttpRouter();

$router->addRoute('/', function() {
    return 'Hello, World!';
});

$router->addRoute('/hello', function() {
    return 'World!';
});

$server->setRequestHandler(function($request, $response) use ($router) {
    // For now, using simple hardcoded routing until PHP callback integration is complete
    $router->dispatch($request->getPath());
});

$result = $server->start();

if ($result && $server->isRunning()) {
    echo "HTTP server running on port " . $server->getPort() . "..." . PHP_EOL;

    echo "You can now test the server:\n";
    echo "curl http://localhost:" . $server->getPort() . "/\n";
    echo "curl http://localhost:" . $server->getPort() . "/hello\n";
    echo "\nPress Ctrl+C to stop the server\n\n";

    // Keep the server running for a limited time for testing
    $count = 0;
    while ($server->isRunning() && $count < 30) {
        sleep(1);
        $count++;
        if ($count % 5 == 0) {
            echo "Server still running... ($count/30 seconds)\n";
        }
    }

    echo "Stopping server...\n";
    $server->stop();
} else {
    echo "Failed to start server!" . PHP_EOL;
}
