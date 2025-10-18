const std = @import("std");
const php = @import("phpzx").c;
const phpzx = @import("phpzx");

const PhpDiagnostic = phpzx.PhpDiagnostic;
const PhpFunction = phpzx.PhpFunction;
const PhpArray = phpzx.PhpArray;
const PhpType = phpzx.PhpType;
const check_args_count = phpzx.check_args_count;
const check_arg_type = phpzx.check_arg_type;
const parse_arg_closure = phpzx.parse_arg_closure;
const parse_arg_variadic = phpzx.parse_arg_variadic;

pub extern var executor_globals: php.zend_executor_globals;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;

// Simple helper functions
inline fn getArrayAt(arrays: [*c]php.zval, index: c_int) [*c]php.zval {
    return arrays + @as(usize, @intCast(index));
}

inline fn getPosAt(array_pos: [*c]u32, index: c_int) [*c]u32 {
    return array_pos + @as(usize, @intCast(index));
}

inline fn getParamAt(params: [*c]php.zval, index: c_int) [*c]php.zval {
    return params + @as(usize, @intCast(index));
}

inline fn isZvalType(zval: [*c]php.zval, zval_type: c_int) bool {
    return php.zval_get_type(zval) == zval_type;
}

inline fn setZvalUndef(zval: [*c]php.zval) void {
    zval.*.u1.type_info = php.IS_UNDEF;
}

inline fn setZvalNull(zval: [*c]php.zval) void {
    zval.*.u1.type_info = php.IS_NULL;
}

inline fn returnNull(return_value: [*c]php.zval) void {
    return_value.*.u1.type_info = php.IS_UNDEF;
}

inline fn isPacked(table: [*c]php.HashTable) bool {
    return php.HT_IS_PACKED(table);
}

inline fn copyZval(dest: [*c]php.zval, src: [*c]const php.zval) void {
    const gc = src.*.value.counted;
    const t = src.*.u1.type_info;
    dest.*.value.counted = gc;
    dest.*.u1.type_info = t;
    if ((t & 0xFF00) != 0) {
        _ = php.zend_gc_addref(&gc.*.gc);
    }
}

inline fn getNextArrayElement(arr_zval: [*c]php.zval, pos: *u32) ?[*c]php.zval {
    const arr = arr_zval.*.value.arr;
    const is_packed = isPacked(arr);

    while (pos.* < arr.*.nNumUsed) {
        const elem = if (is_packed)
            &arr.*.unnamed_0.arPacked[pos.*]
        else
            &arr.*.unnamed_0.arData[pos.*].val;

        pos.* +%= 1;
        if (!isZvalType(elem, php.IS_UNDEF)) {
            return elem;
        }
    }
    return null;
}

/// Main extension function
pub export fn zif_arr_map(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) void {
    var diag = PhpDiagnostic{};
    var func = PhpFunction.new(execute_data);

    check_args_count(&diag, &func, 2, std.math.maxInt(c_int)) catch |err| {
        diag.report(err);
        return;
    };

    var fci: php.zend_fcall_info = undefined;
    var fci_cache: php.zend_fcall_info_cache = undefined;
    parse_arg_closure(&diag, &func, 1, &fci, &fci_cache) catch |err| {
        diag.report(err);
        return;
    };

    var arrays: [*c]php.zval = null;
    var n_arrays: c_int = 0;
    diag.args = &arrays[0];
    parse_arg_variadic(&diag, &func, 2, &arrays, &n_arrays) catch |err| {
        diag.report(err);
        return;
    };

    var result: php.zval = undefined;
    var maxlen: u32 = 0;

    if (n_arrays == 1) {
        // Single array case
        check_arg_type(&diag, 2, &arrays[0], PhpType.Array) catch |err| {
            diag.report(err);
            return;
        };

        var in = PhpArray.from(&arrays[0]);
        maxlen = in.table.*.nNumOfElements;

        // Early return for empty array or no callback
        if (fci.size == 0 or maxlen == 0) {
            php.ZVAL_COPY(return_value, &arrays[0]);
            return;
        }

        fci.retval = &result;
        fci.param_count = 1;

        if (isPacked(in.table)) {
            // Handle packed (numeric) arrays
            var out = PhpArray.new(return_value, in.table.*.nNumUsed);
            var undefs: u32 = 0;

            while (in.hasNext()) {
                const cur = in.current;
                if (!isZvalType(cur, php.IS_UNDEF)) {
                    fci.params = cur;
                    const ret = php.zend_call_function(&fci, &fci_cache);
                    __builtin_assume(ret == php.SUCCESS);
                    if (isZvalType(&result, php.IS_UNDEF)) {
                        out.finalize();
                        out.destroy();
                        php.RETURN_NULL(return_value);
                        return;
                    }
                } else {
                    setZvalUndef(&result);
                    undefs += 1;
                }
                out.fill(&result);
                _ = in.next();
            }

            out.finalize();
            out.table.*.nNumOfElements -%= undefs;
        } else {
            // Handle unpacked (mixed/associative) arrays
            php.array_init_size(return_value, maxlen);
            const output = php.Z_ARRVAL_P(return_value);
            php.zend_hash_real_init_mixed(output);

            const ht = in.table;
            const buckets = ht.*.unnamed_0.arData;
            const num_used = ht.*.nNumUsed;

            for (0..num_used) |i| {
                const bucket = &buckets[i];
                const zval_ptr = &bucket.*.val;

                if (isZvalType(zval_ptr, php.IS_UNDEF)) continue;

                fci.params = zval_ptr;
                const ret = php.zend_call_function(&fci, &fci_cache);
                __builtin_assume(ret == php.SUCCESS);

                if (isZvalType(&result, php.IS_UNDEF)) {
                    php.zend_array_destroy(output);
                    returnNull(return_value);
                    return;
                }

                // Preserve original key
                if (bucket.*.key) |str_key| {
                    _ = php._zend_hash_append(output, str_key, &result);
                } else {
                    _ = php.zend_hash_index_add_new(output, bucket.*.h, &result);
                }
            }
        }
    } else {
        // Multiple arrays case
        const array_pos = @as([*c]u32, @ptrCast(@alignCast(php._ecalloc(@intCast(n_arrays), @sizeOf(php.HashPosition)))));
        defer php._efree(@ptrCast(array_pos));

        // Validate all arrays and find max length
        var i: c_int = 0;
        while (i < n_arrays) : (i += 1) {
            const arr = getArrayAt(arrays, i);
            if (!isZvalType(arr, php.IS_ARRAY)) {
                php.zend_argument_type_error(@intCast(i + 2), "must be of type array, %s given", php.zend_zval_value_name(arr));
                return;
            }
            const len = php.zend_hash_num_elements(arr.*.value.arr);
            if (len > maxlen) {
                maxlen = len;
            }
        }

        // Initialize return array
        const return_arr = if (maxlen <= 8) php._zend_new_array_0() else php._zend_new_array(maxlen);
        return_value.*.value.arr = return_arr;
        return_value.*.u1.type_info = @as(u32, @bitCast((php.IS_ARRAY | ((1 << 0) << 8)) | ((1 << 1) << 8)));

        if (fci.size == 0) {
            // No callback - zip arrays without calling function
            var k: c_int = 0;
            while (k < maxlen) : (k +%= 1) {
                // Create inner array for this iteration
                const inner_arr = if (n_arrays <= 8) php._zend_new_array_0() else php._zend_new_array(@intCast(n_arrays));
                result.value.arr = inner_arr;
                result.u1.type_info = @as(u32, @bitCast((php.IS_ARRAY | ((1 << 0) << 8)) | ((1 << 1) << 8)));

                // Collect one element from each array
                i = 0;
                while (i < n_arrays) : (i += 1) {
                    var zv: php.zval = undefined;
                    const arr = getArrayAt(arrays, i);
                    const pos = getPosAt(array_pos, i);

                    if (getNextArrayElement(arr, pos)) |elem| {
                        copyZval(&zv, elem);
                    } else {
                        setZvalNull(&zv);
                    }

                    _ = php.zend_hash_next_index_insert_new(result.value.arr, &zv);
                }

                _ = php.zend_hash_next_index_insert_new(return_value.*.value.arr, &result);
            }
        } else {
            // With callback - zip arrays and call function
            const params = @as([*c]php.zval, @ptrCast(@alignCast(php._safe_emalloc(@intCast(n_arrays), @sizeOf(php.zval), 0))));
            defer php._efree(@ptrCast(params));

            fci.retval = &result;
            fci.param_count = @intCast(n_arrays);
            fci.params = params;

            var k: c_int = 0;
            while (k < maxlen) : (k +%= 1) {
                // Collect one element from each array
                i = 0;
                while (i < n_arrays) : (i += 1) {
                    const arr = getArrayAt(arrays, i);
                    const pos = getPosAt(array_pos, i);
                    const param = getParamAt(params, i);

                    if (getNextArrayElement(arr, pos)) |elem| {
                        copyZval(param, elem);
                    } else {
                        setZvalNull(param);
                    }
                }

                // Call the callback
                const ret = php.zend_call_function(&fci, &fci_cache);
                __builtin_assume(ret == php.SUCCESS);

                if (isZvalType(&result, php.IS_UNDEF)) {
                    php.zend_array_destroy(return_value.*.value.arr);

                    // Clean up params
                    i = 0;
                    while (i < n_arrays) : (i += 1) {
                        php.zval_ptr_dtor(getParamAt(params, i));
                    }

                    returnNull(return_value);
                    return;
                }

                // Clean up params for this iteration
                i = 0;
                while (i < n_arrays) : (i += 1) {
                    php.zval_ptr_dtor(getParamAt(params, i));
                }

                _ = php.zend_hash_next_index_insert_new(return_value.*.value.arr, &result);
            }
        }
    }
}
