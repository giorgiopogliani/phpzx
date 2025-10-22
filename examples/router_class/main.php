<?php

$router = new Router();

// Simple route without parameters
$router->addRoute("/", function() {
    echo "Home page\n";
});

// Route with one parameter
$router->addRoute("/posts/{id}", function($id) {
    echo "Post ID: $id\n";
});

// Route with multiple parameters
$router->addRoute("/posts/{post_id}/comments/{comment_id}", function($post_id, $comment_id) {
    echo "Post ID: $post_id, Comment ID: $comment_id\n";
});

// Route with parameter at the end
$router->addRoute("/users/{username}", function($username) {
    echo "User: $username\n";
});

echo "Total routes: " . $router->getRouteCount() . "\n\n";

// Test dispatching
echo "Testing /\n";
$router->dispatch("/");

echo "\nTesting /posts/123\n";
$router->dispatch("/posts/123");

echo "\nTesting /posts/456/comments/789\n";
$router->dispatch("/posts/456/comments/789");

echo "\nTesting /users/john_doe\n";
$router->dispatch("/users/john_doe");

echo "\nTesting /unknown\n";
$result = $router->dispatch("/unknown");
echo "Result: $result\n";


echo "Count: " . $router->getRouteCount() . PHP_EOL;

// Adding 100 routes
for ($i = 1; $i <= 100; $i++) {
    $router->addRoute("/route$i", function() use ($i) {
        echo "Route $i\n";
    });
    if ($i <= 10 || $i % 10 == 0) {
        echo "Count: " . $router->getRouteCount() . PHP_EOL;
    }
}

echo "Done adding routes\n";

$router->addRoute("/products", function() {
    echo "Products page handler called!\n";
});

$router->addRoute("/contact", function() {
    echo "Contact page handler called!\n";
});

echo "\nTotal routes: " . $router->getRouteCount() . PHP_EOL;

echo "Dispatching /route3" . PHP_EOL;
$router->dispatch("/route3");

echo "Dispatching /products" . PHP_EOL;
$router->dispatch("/products");

echo "Dispatching /contact" . PHP_EOL;
$router->dispatch("/contact");
