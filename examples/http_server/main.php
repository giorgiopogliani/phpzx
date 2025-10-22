<?php

echo "=== HTTP Server Example ===\n\n";

// Create a new HTTP server instance
$server = new HttpServer();

echo "Server created successfully!\n";
echo "Default port: " . $server->getPort() . "\n";

// Set a custom port
$server->setPort(9090);
echo "Port set to: " . $server->getPort() . "\n";

// Set up a request handler
$server->setRequestHandler(function($request, &$response) {
    echo "Handling request: " . $request['method'] . " " . $request['path'] . "\n";

    // Log request details
    echo "Query string: " . $request['query'] . "\n";
    echo "Headers: " . json_encode($request['headers']) . "\n";
    echo "Body length: " . strlen($request['body']) . "\n";

    $path = $request['path'];
    $method = $request['method'];

    // Simple routing
    if ($path === '/') {
        $response['status'] = 200;
        $response['headers']['Content-Type'] = 'text/html';
        $response['body'] = '<h1>Welcome to Zig HTTP Server!</h1><p>Server running via PHP extension powered by Zig + http.zig</p>';
    }
    elseif ($path === '/api/hello') {
        $response['status'] = 200;
        $response['headers']['Content-Type'] = 'application/json';
        $response['body'] = json_encode([
            'message' => 'Hello from Zig HTTP Server!',
            'method' => $method,
            'timestamp' => date('c'),
            'powered_by' => 'Zig + PHP'
        ]);
    }
    elseif ($path === '/api/echo' && $method === 'POST') {
        $response['status'] = 200;
        $response['headers']['Content-Type'] = 'application/json';
        $response['body'] = json_encode([
            'echo' => $request['body'],
            'received_at' => date('c')
        ]);
    }
    elseif (strpos($path, '/user/') === 0) {
        // Extract user ID from path
        $userId = substr($path, 6);
        $response['status'] = 200;
        $response['headers']['Content-Type'] = 'application/json';
        $response['body'] = json_encode([
            'user_id' => $userId,
            'name' => 'User ' . $userId,
            'status' => 'active'
        ]);
    }
    else {
        $response['status'] = 404;
        $response['headers']['Content-Type'] = 'application/json';
        $response['body'] = json_encode([
            'error' => 'Not Found',
            'path' => $path,
            'available_endpoints' => [
                '/' => 'Home page',
                '/api/hello' => 'Hello API (GET)',
                '/api/echo' => 'Echo API (POST)',
                '/user/{id}' => 'User info (GET)'
            ]
        ]);
    }
});

echo "\nRequest handler set successfully!\n";

// Check if server is running
echo "Server running: " . ($server->isRunning() ? 'Yes' : 'No') . "\n";

// Start the server
echo "\nStarting HTTP server on port " . $server->getPort() . "...\n";
$result = $server->start();

if ($result) {
    echo "✅ Server started successfully!\n";
    echo "🌐 You can now access:\n";
    echo "   • http://127.0.0.1:9090/\n";
    echo "   • http://127.0.0.1:9090/api/hello\n";
    echo "   • http://127.0.0.1:9090/user/123\n";
    echo "   • POST to http://127.0.0.1:9090/api/echo with JSON body\n";
    echo "\n";

    echo "Server is running: " . ($server->isRunning() ? 'Yes' : 'No') . "\n";

    echo "\nServer is now running. Press Ctrl+C to stop...\n";
    
    // Keep the server running indefinitely
    while ($server->isRunning()) {
        sleep(1);
    }
    
    echo "\nServer has stopped.\n";

} else {
    echo "❌ Failed to start server!\n";
}

echo "\n=== End of HTTP Server Example ===\n";
