<?php

$sample = new Sample(1);

$reflection = new ReflectionClass($sample);
var_dump($reflection->getMethods());

// echo $sample->getValue();
