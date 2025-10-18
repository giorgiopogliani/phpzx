# PHP SAPI Example with phpzx

This example demonstrates how to build a custom PHP SAPI (Server API) using Zig and the phpzx library. A SAPI is an interface that allows you to embed PHP into your own applications, giving you full control over how PHP scripts are executed.

## What is a PHP SAPI?

PHP SAPI is the interface between PHP and the host application. Common SAPIs include:
- CLI (command-line interface)
- Apache module
- FPM (FastCGI Process Manager)
- CGI

This example shows how to create a custom SAPI that can execute PHP scripts from within a Zig application.

## Features

- Embeds PHP interpreter in a Zig application
- Executes PHP scripts from files
- Full access to PHP functionality
- Demonstrates proper initialization and shutdown

## Prerequisites

- Zig 0.13.0 or later
- PHP development files (php-dev or php-devel package)
- php-config must be available in PATH

## Building

```bash
zig build
```

This will:
1. Download the phpzx dependency
2. Configure PHP include paths and libraries via php-config
3. Build the executable SAPI

## Running

Execute a PHP script using the custom SAPI:

```bash
zig build run -- test.php
```

Or after building, run directly:

```bash
./zig-out/bin/php-sapi test.php
```

## Example Output

```
Hello from PHP SAPI!
PHP Version: 8.3.0
Array sum: 15
Fibonacci(10): 55
Data: {
    "name": "Custom PHP SAPI",
    "built_with": "Zig + phpzx",
    "status": "working"
}
PHP script executed successfully
```

## How It Works

1. **Initialization**: The SAPI initializes the PHP embed layer using `php_embed_init()`
2. **Script Loading**: The PHP script is read from the filesystem
3. **Execution**: The script is executed using `zend_eval_string()`
4. **Shutdown**: The PHP embed layer is properly shut down with `php_embed_shutdown()`

## Code Structure

- `src/main.zig` - Main SAPI implementation
- `test.php` - Example PHP script demonstrating various features
- `build.zig` - Build configuration with PHP linking
- `build.zig.zon` - Dependencies configuration

## Use Cases

Custom PHP SAPIs can be useful for:
- Embedding PHP in desktop applications
- Creating custom PHP runtimes
- Building specialized PHP execution environments
- Integrating PHP into game engines or other applications
- Creating custom testing frameworks

## Learn More

- [phpzx Library](https://github.com/giorgiopogliani/phpzx)
- [PHP Embed Documentation](https://www.php.net/manual/en/features.commandline.php)
- [Zig Build System](https://ziglang.org/learn/build-system/)
