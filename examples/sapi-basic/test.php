<?php

echo "Hello from PHP SAPI!\n";
echo "PHP Version: " . PHP_VERSION . "\n";

$numbers = [1, 2, 3, 4, 5];
echo "Array sum: " . array_sum($numbers) . "\n";

function fibonacci($n) {
    if ($n <= 1) return $n;
    return fibonacci($n - 1) + fibonacci($n - 2);
}

echo "Fibonacci(10): " . fibonacci(10) . "\n";

$data = [
    'name' => 'Custom PHP SAPI',
    'built_with' => 'Zig + phpzx',
    'status' => 'working'
];

echo "Data: " . json_encode($data, JSON_PRETTY_PRINT) . "\n";
