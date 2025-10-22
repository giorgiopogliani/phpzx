# PHPZX

Develop PHP extensions in Zig with zero overhead, higher performance, and improved ergonomics.

## Features

- **Minimal Overhead**: Designed to minimize the overhead associated with PHP extension development when not using C.
- **Improved Ergonomics**: Provides a more intuitive and ergonomic API for writing PHP extensions and avoid C macros.
- **Enhanced Performance**: Optimized for high-performance PHP extensions.

## Usage

```zig
const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

pub inline fn num_double(value: c.zend_long) c.zend_long {
  return value * 2;
}

// Usage
var module = phpzx.PhpModuleBuilder
    .new("basic")
    .function("num_double", num_double)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}

```

Or pass a class

```zig
const std = @import("std");
const phpzx = @import("phpzx");
const c = phpzx.c;

// Define your PHP class object structure with methods!
const SampleObject = struct {
    value: c.zend_long,
    std: c.zend_object,

    // PHP methods defined directly on the struct
    pub fn __construct(self: *SampleObject) void {
        self.*.value = 10;
    }

    pub fn getValue(self: *SampleObject) c.zend_long {
        return self.*.value;
    }

    // Method with parameter - automatically parsed!
    pub fn setValue(self: *SampleObject, new_value: c.zend_long) void {
        self.*.value = new_value;
    }

    // Method with parameter that returns a value
    pub fn add(self: *SampleObject, amount: c.zend_long) c.zend_long {
        self.*.value += amount;
        return self.*.value;
    }
};

// Register the class - everything is auto-generated!
const Sample = phpzx.PhpClass("Sample", SampleObject);

// Module startup - just call register on each class
pub export fn zm_startup_sample(arg_type: c_int, arg_module_number: c_int) callconv(.c) c.zend_result {
    _ = arg_type;
    _ = arg_module_number;

    return Sample.register();
}

var module = phpzx.PhpModuleBuilder
    .new("zigsample")
    .minit(zm_startup_sample)
    .build();

pub export fn get_module() *c.zend_module_entry {
    return &module;
}
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## Testing

TOOD.

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.
