<?php

/**
 * Test case runner for comparing count vsarr_count
 */
class ArrayMapTester {
    public function runPerformanceTest() {
        echo "\n=== Performance Comparison ===\n";

        $test_sizes = [100, 1000, 10000];

        foreach ($test_sizes as $size) {
            $array = range(1, $size);

            // Test count performance
            $start = microtime(true);
            for ($i = 0; $i < 1000; $i++) {
                count($array);
            }
            $count_time = microtime(true) - $start;

            // Test arr_count performance
            $start = microtime(true);
            for ($i = 0; $i < 1000; $i++) {
                arr_count($array);
            }
            $arr_count_time = microtime(true) - $start;

            $improvement = (($count_time - $arr_count_time) / $count_time) * 100;

            echo "Array size: $size elements (1000 iterations)\n";
            echo "  count: " . number_format($count_time * 1000, 4) . "ms\n";
            echo "  arr_count: " . number_format($arr_count_time * 1000, 4) . "ms\n";
            echo "  Performance improvement: " . number_format($improvement, 2) . "%\n\n";
        }
    }
}

$tester = new ArrayMapTester();
$tester->runPerformanceTest();
