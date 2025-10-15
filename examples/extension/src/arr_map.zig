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

    var i: c_int = 0;
    var k: c_int = 0;
    var result: php.zval = undefined;
    var maxlen: u32 = 0;

    if (n_arrays == 1) {
        check_arg_type(&diag, 2, &arrays[0], PhpType.Array) catch |err| {
            diag.report(err);
            return;
        };

        var in = PhpArray.from(&arrays[0]);
        maxlen = in.table.*.nNumOfElements;

        if (!(fci.size != 0) or !(maxlen != 0)) {
            php.ZVAL_COPY(return_value, &arrays[0]);
            return;
        }

        fci.retval = &result;
        fci.param_count = 1;

        if (php.HT_IS_PACKED(in.table)) {

            var out = PhpArray.new(return_value, in.table.*.nNumUsed);
            var undefs: u32 = 0;

            while (in.hasNext()) {
                const cur = in.current;
                if (php.zval_get_type(cur) != php.IS_UNDEF) {
                    fci.params = cur;
                    const ret: php.zend_result = php.zend_call_function(&fci, &fci_cache);
                    __builtin_assume(ret == php.SUCCESS);
                    if (result.u1.type_info == php.IS_UNDEF) {
                        out.finalize();
                        php.zend_array_destroy(out.table);
                        php.RETURN_NULL(return_value);
                        return;
                    }
                } else {
                    php.ZVAL_UNDEF(&result);
                    undefs += 1;
                }
                out.fill(&result);
                _ = in.next();
            }

            out.finalize();
            out.table.*.nNumOfElements -%= undefs;
        } else {
            var num_key: php.zend_ulong = undefined;
            var str_key: [*c]php.zend_string = undefined;

            php.array_init_size(return_value, maxlen);
            const output: [*c]php.HashTable = php.Z_ARRVAL_P(return_value);
            php.zend_hash_real_init_mixed(output);

            while (true) {
                var __ht: [*c]const php.HashTable = in.table;
                _ = &__ht;
                var _p: [*c]php.Bucket = __ht.*.unnamed_0.arData + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 0)))));
                _ = &_p;
                var _end: [*c]const php.Bucket = __ht.*.unnamed_0.arData + __ht.*.nNumUsed;
                _ = &_end;
                __builtin_assume(!((__ht.*.u.flags & @as(u32, @bitCast(@as(c_int, 1) << @intCast(2)))) != @as(u32, @bitCast(@as(c_int, 0)))));
                while (_p != @as([*c]php.Bucket, @ptrCast(@volatileCast(@constCast(_end))))) : (_p += 1) {
                    var _z: [*c]php.zval = &_p.*.val;
                    _ = &_z;
                    if (false and (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_z.*)))) == @as(c_int, 12))) {
                        _z = _z.*.value.zv;
                    }
                    if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_z.*)))) == @as(c_int, 0)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) continue;
                    num_key = _p.*.h;
                    str_key = _p.*.key;
                    fci.params = _z;
                    {
                        const ret: php.zend_result = php.zend_call_function(&fci, &fci_cache);
                        __builtin_assume(ret == php.SUCCESS);
                        if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&result)))) == @as(c_int, 0)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
                            php.zend_array_destroy(output);
                            while (true) {
                                while (true) {
                                    return_value.*.u1.type_info = 1;
                                    break;
                                }
                                return;
                            }
                        }
                        if (str_key != null) {
                            _ = php._zend_hash_append(output, str_key, &result);
                        } else {
                            _ = php.zend_hash_index_add_new(output, num_key, &result);
                        }
                    }
                }
                break;
            }
        }

        // più di un array
    } else {
        var array_pos: [*c]u32 = @as([*c]php.HashPosition, @ptrCast(@alignCast(php._ecalloc(@as(usize, @bitCast(@as(c_long, n_arrays))), @sizeOf(php.HashPosition)))));
        _ = &array_pos;
        {
            i = 0;
            while (i < n_arrays) : (i += 1) {
                if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&(blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*)))) != @as(c_int, 7)) {
                    php.zend_argument_type_error(@as(u32, @bitCast(i + @as(c_int, 2))), "must be of type array, %s given", php.zend_zval_value_name(&(blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*));
                    php._efree(@as(?*anyopaque, @ptrCast(array_pos)));
                    while (true) {
                        _ = &return_value;
                        return;
                    }
                }
                if (php.zend_hash_num_elements((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*.value.arr) > maxlen) {
                    maxlen = php.zend_hash_num_elements((blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*.value.arr);
                }
            }
        }
        while (true) {
            var __arr: [*c]php.zend_array = if (__builtin_constant_p(maxlen) != 0) if (maxlen <= @as(u32, @bitCast(@as(c_int, 8)))) php._zend_new_array_0() else php._zend_new_array(maxlen) else php._zend_new_array(maxlen);
            _ = &__arr;
            var __z: [*c]php.zval = return_value;
            _ = &__z;
            __z.*.value.arr = __arr;
            __z.*.u1.type_info = @as(u32, @bitCast((@as(c_int, 7) | ((@as(c_int, 1) << @intCast(0)) << @intCast(8))) | ((@as(c_int, 1) << @intCast(1)) << @intCast(8))));
            break;
        }
        if (!(fci.size != @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))))) {
            var zv: php.zval = undefined;
            _ = &zv;
            {
                k = 0;
                while (k < maxlen) : (k +%= 1) {
                    while (true) {
                        var __arr: [*c]php.zend_array = if (__builtin_constant_p(n_arrays) != 0) if (@as(u32, @bitCast(n_arrays)) <= @as(u32, @bitCast(@as(c_int, 8)))) php._zend_new_array_0() else php._zend_new_array(@as(u32, @bitCast(n_arrays))) else php._zend_new_array(@as(u32, @bitCast(n_arrays)));
                        _ = &__arr;
                        var __z: [*c]php.zval = &result;
                        _ = &__z;
                        __z.*.value.arr = __arr;
                        __z.*.u1.type_info = @as(u32, @bitCast((@as(c_int, 7) | ((@as(c_int, 1) << @intCast(0)) << @intCast(8))) | ((@as(c_int, 1) << @intCast(1)) << @intCast(8))));
                        break;
                    }
                    {
                        i = 0;
                        while (i < n_arrays) : (i += 1) {
                            var pos: u32 = (blk: {
                                const tmp = i;
                                if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*;
                            _ = &pos;
                            if (((blk: {
                                const tmp = i;
                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*.value.arr.*.u.flags & @as(u32, @bitCast(@as(c_int, 1) << @intCast(2)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                while (true) {
                                    if (pos >= (blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.nNumUsed) {
                                        while (true) {
                                            (&zv).*.u1.type_info = 1;
                                            break;
                                        }
                                        break;
                                    } else if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&(blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.unnamed_0.arPacked[pos])))) != @as(c_int, 0)) {
                                        while (true) {
                                            var _z1: [*c]php.zval = &zv;
                                            _ = &_z1;
                                            var _z2: [*c]const php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*.value.arr.*.unnamed_0.arPacked[pos];
                                            _ = &_z2;
                                            var _gc: [*c]php.zend_refcounted = _z2.*.value.counted;
                                            _ = &_gc;
                                            var _t: u32 = _z2.*.u1.type_info;
                                            _ = &_t;
                                            while (true) {
                                                _z1.*.value.counted = _gc;
                                                _z1.*.u1.type_info = _t;
                                                break;
                                            }
                                            if ((_t & @as(u32, @bitCast(@as(c_int, 65280)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                                _ = php.zend_gc_addref(&_gc.*.gc);
                                            }
                                            break;
                                        }
                                        (blk: {
                                            const tmp = i;
                                            if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                        }).* = pos +% @as(u32, @bitCast(@as(c_int, 1)));
                                        break;
                                    }
                                    pos +%= 1;
                                }
                            } else {
                                while (true) {
                                    if (pos >= (blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.nNumUsed) {
                                        while (true) {
                                            (&zv).*.u1.type_info = 1;
                                            break;
                                        }
                                        break;
                                    } else if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&(blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.unnamed_0.arData[pos].val)))) != @as(c_int, 0)) {
                                        while (true) {
                                            var _z1: [*c]php.zval = &zv;
                                            _ = &_z1;
                                            var _z2: [*c]const php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*.value.arr.*.unnamed_0.arData[pos].val;
                                            _ = &_z2;
                                            var _gc: [*c]php.zend_refcounted = _z2.*.value.counted;
                                            _ = &_gc;
                                            var _t: u32 = _z2.*.u1.type_info;
                                            _ = &_t;
                                            while (true) {
                                                _z1.*.value.counted = _gc;
                                                _z1.*.u1.type_info = _t;
                                                break;
                                            }
                                            if ((_t & @as(u32, @bitCast(@as(c_int, 65280)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                                _ = php.zend_gc_addref(&_gc.*.gc);
                                            }
                                            break;
                                        }
                                        (blk: {
                                            const tmp = i;
                                            if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                        }).* = pos +% @as(u32, @bitCast(@as(c_int, 1)));
                                        break;
                                    }
                                    pos +%= 1;
                                }
                            }
                            _ = php.zend_hash_next_index_insert_new(result.value.arr, &zv);
                        }
                    }
                    _ = php.zend_hash_next_index_insert_new(return_value.*.value.arr, &result);
                }
            }
        } else {
            var params: [*c]php.zval = @as([*c]php.zval, @ptrCast(@alignCast(php._safe_emalloc(@as(usize, @bitCast(@as(c_long, n_arrays))), @sizeOf(php.zval), @as(usize, @bitCast(@as(c_long, @as(c_int, 0))))))));
            _ = &params;
            {
                k = 0;
                while (k < maxlen) : (k +%= 1) {
                    {
                        i = 0;
                        while (i < n_arrays) : (i += 1) {
                            var pos: u32 = (blk: {
                                const tmp = i;
                                if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*;
                            _ = &pos;
                            if (((blk: {
                                const tmp = i;
                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*.value.arr.*.u.flags & @as(u32, @bitCast(@as(c_int, 1) << @intCast(2)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                while (true) {
                                    if (pos >= (blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.nNumUsed) {
                                        while (true) {
                                            (&(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*).*.u1.type_info = 1;
                                            break;
                                        }
                                        break;
                                    } else if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&(blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.unnamed_0.arPacked[pos])))) != @as(c_int, 0)) {
                                        while (true) {
                                            var _z1: [*c]php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*;
                                            _ = &_z1;
                                            var _z2: [*c]const php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*.value.arr.*.unnamed_0.arPacked[pos];
                                            _ = &_z2;
                                            var _gc: [*c]php.zend_refcounted = _z2.*.value.counted;
                                            _ = &_gc;
                                            var _t: u32 = _z2.*.u1.type_info;
                                            _ = &_t;
                                            while (true) {
                                                _z1.*.value.counted = _gc;
                                                _z1.*.u1.type_info = _t;
                                                break;
                                            }
                                            if ((_t & @as(u32, @bitCast(@as(c_int, 65280)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                                _ = php.zend_gc_addref(&_gc.*.gc);
                                            }
                                            break;
                                        }
                                        (blk: {
                                            const tmp = i;
                                            if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                        }).* = pos +% @as(u32, @bitCast(@as(c_int, 1)));
                                        break;
                                    }
                                    pos +%= 1;
                                }
                            } else {
                                while (true) {
                                    if (pos >= (blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.nNumUsed) {
                                        while (true) {
                                            (&(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*).*.u1.type_info = 1;
                                            break;
                                        }
                                        break;
                                    } else if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&(blk: {
                                        const tmp = i;
                                        if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                    }).*.value.arr.*.unnamed_0.arData[pos].val)))) != @as(c_int, 0)) {
                                        while (true) {
                                            var _z1: [*c]php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*;
                                            _ = &_z1;
                                            var _z2: [*c]const php.zval = &(blk: {
                                                const tmp = i;
                                                if (tmp >= 0) break :blk arrays + @as(usize, @intCast(tmp)) else break :blk arrays - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                            }).*.value.arr.*.unnamed_0.arData[pos].val;
                                            _ = &_z2;
                                            var _gc: [*c]php.zend_refcounted = _z2.*.value.counted;
                                            _ = &_gc;
                                            var _t: u32 = _z2.*.u1.type_info;
                                            _ = &_t;
                                            while (true) {
                                                _z1.*.value.counted = _gc;
                                                _z1.*.u1.type_info = _t;
                                                break;
                                            }
                                            if ((_t & @as(u32, @bitCast(@as(c_int, 65280)))) != @as(u32, @bitCast(@as(c_int, 0)))) {
                                                _ = php.zend_gc_addref(&_gc.*.gc);
                                            }
                                            break;
                                        }
                                        (blk: {
                                            const tmp = i;
                                            if (tmp >= 0) break :blk array_pos + @as(usize, @intCast(tmp)) else break :blk array_pos - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                        }).* = pos +% @as(u32, @bitCast(@as(c_int, 1)));
                                        break;
                                    }
                                    pos +%= 1;
                                }
                            }
                        }
                    }
                    fci.retval = &result;
                    fci.param_count = @as(u32, @bitCast(n_arrays));
                    fci.params = params;
                    var ret: php.zend_result = php.zend_call_function(&fci, &fci_cache);
                    _ = &ret;
                    __builtin_assume(ret == php.SUCCESS);
                    _ = blk: {
                        var __x: @TypeOf(ret) = ret;
                        _ = &__x;
                        break :blk __x;
                    };
                    if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&result)))) == @as(c_int, 0)) {
                        php._efree(@as(?*anyopaque, @ptrCast(array_pos)));
                        php.zend_array_destroy(return_value.*.value.arr);
                        {
                            i = 0;
                            while (i < n_arrays) : (i += 1) {
                                php.zval_ptr_dtor(&(blk: {
                                    const tmp = i;
                                    if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                }).*);
                            }
                        }
                        php._efree(@as(?*anyopaque, @ptrCast(params)));
                        while (true) {
                            while (true) {
                                return_value.*.u1.type_info = 1;
                                break;
                            }
                            return;
                        }
                    } else {
                        {
                            i = 0;
                            while (i < n_arrays) : (i += 1) {
                                php.zval_ptr_dtor(&(blk: {
                                    const tmp = i;
                                    if (tmp >= 0) break :blk params + @as(usize, @intCast(tmp)) else break :blk params - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                }).*);
                            }
                        }
                    }
                    _ = php.zend_hash_next_index_insert_new(return_value.*.value.arr, &result);
                }
            }
            php._efree(@as(?*anyopaque, @ptrCast(params)));
        }
        php._efree(@as(?*anyopaque, @ptrCast(array_pos)));
    }
}
