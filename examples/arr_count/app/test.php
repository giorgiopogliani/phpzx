<?php

declare(strict_types=1);

$tests = [
    'array_map' => [
        fn($value) => $value * 2,
        [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200],
    ],
    'arr_map' => [
        fn($value) => $value * 2,
        [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200],
    ],
];

$iterations = 5000;

function benchmark($title, $callback)
{
    global $iterations;
    $results = [];
    echo 'Benchmarking ' . $title . PHP_EOL;
    foreach (range(0, $iterations) as $value) {
        $start = hrtime(true);
        $callback();
        $results[] = (hrtime(true) - $start) / 1000000;
    }
    echo 'Time: ' . array_sum($results) . PHP_EOL;
}

foreach ($tests as $func => $input) {
    echo json_encode($func(...$input)) . PHP_EOL;
    benchmark($func, fn() => $func(...$input));
    echo json_encode($input) . PHP_EOL . PHP_EOL;
}
