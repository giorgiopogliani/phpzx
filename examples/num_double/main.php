<?php

echo num_double(10) . PHP_EOL;

var_dump(new ReflectionFunction('num_double')->getParameters()[0]->isOptional());
