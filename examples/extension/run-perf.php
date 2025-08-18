<?php

/**
 * Test case runner for comparing array_map vs arr_map
 */
class ArrayMapTester {
    public function runPerformanceTest() {
        echo "\n=== Performance Comparison ===\n";

        $test_sizes = [100, 1000, 10000];
        $callback = function($x) { return $x * 2 + 1; };

        foreach ($test_sizes as $size) {
            $array = range(1, $size);

            // Test array_map performance
            $start = microtime(true);
            for ($i = 0; $i < 100; $i++) {
                array_map($callback, $array);
            }
            $array_map_time = microtime(true) - $start;

            // Test arr_map performance
            $start = microtime(true);
            for ($i = 0; $i < 100; $i++) {
                arr_map($callback, $array);
            }
            $arr_map_time = microtime(true) - $start;

            $improvement = (($array_map_time - $arr_map_time) / $array_map_time) * 100;

            echo "Array size: $size elements (100 iterations)\n";
            echo "  array_map: " . number_format($array_map_time * 1000, 4) . "ms\n";
            echo "  arr_map: " . number_format($arr_map_time * 1000, 4) . "ms\n";
            echo "  Performance improvement: " . number_format($improvement, 2) . "%\n\n";
        }
    }
}

$tester = new ArrayMapTester();
$tester->runPerformanceTest();
