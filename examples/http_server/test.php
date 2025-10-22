<?php

echo "=== Simple HTTP Server Test ===\n\n";

echo "Step 1: Creating HttpServer instance...\n";
$server = new HttpServer();
echo "✓ Server created successfully!\n";

echo "Step 2: Getting default port...\n";
$port = $server->getPort();
echo "✓ Default port: $port\n";

echo "Step 3: Setting port to 9090...\n";
$server->setPort(9090);
echo "✓ Port set successfully\n";

echo "Step 4: Getting updated port...\n";
$port = $server->getPort();
echo "✓ Updated port: $port\n";

echo "Step 5: Checking if server is running...\n";
$running = $server->isRunning();
echo "✓ Server running: " . ($running ? 'Yes' : 'No') . "\n";

echo "Step 6: Setting a simple request handler...\n";
$server->setRequestHandler(function($request, &$response) {
    echo "Handler called with method: " . $request['method'] . "\n";
    $response['status'] = 200;
    $response['body'] = 'Hello World';
});
echo "✓ Request handler set\n";

echo "Step 7: Checking server running status again...\n";
$running = $server->isRunning();
echo "✓ Server running: " . ($running ? 'Yes' : 'No') . "\n";

echo "\n=== Basic functionality test completed successfully! ===\n";
echo "If you see this message, the basic server operations work.\n";
echo "The segfault might be in the start() method.\n\n";

echo "Step 8: Attempting to start server (this might crash)...\n";
$result = $server->start();

sleep(10);
