const std = @import("std");
const php = @import("phpzx");

pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;

pub extern var zend_ce_countable: [*c]php.zend_class_entry;

pub const struct__zend_class_entry = extern struct {
    type: u8 = @import("std").mem.zeroes(u8),
    name: [*c]php.zend_string = @import("std").mem.zeroes([*c]php.zend_string),
    unnamed_0: php.union_unnamed_7 = @import("std").mem.zeroes(php.union_unnamed_7),
    refcount: c_int = @import("std").mem.zeroes(c_int),
    ce_flags: u32 = @import("std").mem.zeroes(u32),
    default_properties_count: c_int = @import("std").mem.zeroes(c_int),
    default_static_members_count: c_int = @import("std").mem.zeroes(c_int),
    default_properties_table: [*c]php.zval = @import("std").mem.zeroes([*c]php.zval),
    default_static_members_table: [*c]php.zval = @import("std").mem.zeroes([*c]php.zval),
    static_members_table__ptr: [*c]php.zval = @import("std").mem.zeroes([*c]php.zval),
    function_table: php.HashTable = @import("std").mem.zeroes(php.HashTable),
    properties_info: php.HashTable = @import("std").mem.zeroes(php.HashTable),
    constants_table: php.HashTable = @import("std").mem.zeroes(php.HashTable),
    mutable_data__ptr: [*c]php.zend_class_mutable_data = @import("std").mem.zeroes([*c]php.zend_class_mutable_data),
    inheritance_cache: [*c]php.zend_inheritance_cache_entry = @import("std").mem.zeroes([*c]php.zend_inheritance_cache_entry),
    properties_info_table: [*c][*c]php.struct__zend_property_info = @import("std").mem.zeroes([*c][*c]php.struct__zend_property_info),
    constructor: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    destructor: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    clone: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __get: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __set: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __unset: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __isset: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __call: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __callstatic: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __tostring: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __debugInfo: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __serialize: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    __unserialize: [*c]php.zend_function = @import("std").mem.zeroes([*c]php.zend_function),
    default_object_handlers: [*c]const php.zend_object_handlers = @import("std").mem.zeroes([*c]const php.zend_object_handlers),
    iterator_funcs_ptr: [*c]php.zend_class_iterator_funcs = @import("std").mem.zeroes([*c]php.zend_class_iterator_funcs),
    arrayaccess_funcs_ptr: [*c]php.zend_class_arrayaccess_funcs = @import("std").mem.zeroes([*c]php.zend_class_arrayaccess_funcs),
    unnamed_1: php.union_unnamed_17 = @import("std").mem.zeroes(php.union_unnamed_17),
    get_iterator: ?*const fn ([*c]php.zend_class_entry, [*c]php.zval, c_int) callconv(.c) [*c]php.zend_object_iterator = @import("std").mem.zeroes(?*const fn ([*c]php.zend_class_entry, [*c]php.zval, c_int) callconv(.c) [*c]php.zend_object_iterator),
    get_static_method: ?*const fn ([*c]php.zend_class_entry, [*c]php.zend_string) callconv(.c) [*c]php.zend_function = @import("std").mem.zeroes(?*const fn ([*c]php.zend_class_entry, [*c]php.zend_string) callconv(.c) [*c]php.zend_function),
    serialize: ?*const fn ([*c]php.zval, [*c][*c]u8, [*c]usize, ?*php.zend_serialize_data) callconv(.c) c_int = @import("std").mem.zeroes(?*const fn ([*c]php.zval, [*c][*c]u8, [*c]usize, ?*php.zend_serialize_data) callconv(.c) c_int),
    unserialize: ?*const fn ([*c]php.zval, [*c]php.zend_class_entry, [*c]const u8, usize, ?*php.zend_unserialize_data) callconv(.c) c_int = @import("std").mem.zeroes(?*const fn ([*c]php.zval, [*c]php.zend_class_entry, [*c]const u8, usize, ?*php.zend_unserialize_data) callconv(.c) c_int),
    num_interfaces: u32 = @import("std").mem.zeroes(u32),
    num_traits: u32 = @import("std").mem.zeroes(u32),
    num_hooked_props: u32 = @import("std").mem.zeroes(u32),
    num_hooked_prop_variance_checks: u32 = @import("std").mem.zeroes(u32),
    unnamed_2: php.union_unnamed_18 = @import("std").mem.zeroes(php.union_unnamed_18),
    trait_names: [*c]php.zend_class_name = @import("std").mem.zeroes([*c]php.zend_class_name),
    trait_aliases: [*c][*c]php.zend_trait_alias = @import("std").mem.zeroes([*c][*c]php.zend_trait_alias),
    trait_precedences: [*c][*c]php.zend_trait_precedence = @import("std").mem.zeroes([*c][*c]php.zend_trait_precedence),
    attributes: [*c]php.HashTable = @import("std").mem.zeroes([*c]php.HashTable),
    enum_backing_type: u32 = @import("std").mem.zeroes(u32),
    backed_enum_table: [*c]php.HashTable = @import("std").mem.zeroes([*c]php.HashTable),
    doc_comment: [*c]php.zend_string = @import("std").mem.zeroes([*c]php.zend_string),
    info: php.union_unnamed_19 = @import("std").mem.zeroes(php.union_unnamed_19),
};

pub inline fn php_get_long(arg_zv: [*c]php.zval) php.zend_long {
    var zv = arg_zv;
    _ = &zv;
    if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&zv.*)))) == @as(c_int, 4)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) {
        return zv.*.value.lval;
    } else {
        var ret: php.zend_long = php.zval_get_long_func(zv, @as(c_int, 0) != 0);
        _ = &ret;
        php.zval_ptr_dtor(zv);
        return ret;
    }
    return @import("std").mem.zeroes(php.zend_long);
}
// pub inline fn parse_arg_array(diag: *php.PhpDiagnostic, func: *php.PhpFunction, index: u32, array: *[*c]php.zval, types: []const php.PhpType) !void {
//     const arg = func.args + index;
//     const arg_type: php.PhpType = @enumFromInt(php.zval_get_type(arg));

//     for (types) |t| {
//       if (arg_type == t) {
//         array.* = arg;
//         return;
//       }
//     }

//     diag.num_arg = index;
//     diag.args = arg;
//     diag.expected_type = php.Z_EXPECTED_ITERABLE;

//     return php.PhpError.ErrorUnexpectedType;
// }

/// Main extension function
// pub export fn zif_arr_count(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) void {
//     var diag = php.PhpDiagnostic{};
//     var func = php.PhpFunction.new(execute_data);

//     php.check_args_count(&diag, &func, 1, 1) catch |err| {
//         diag.report(err);
//         return;
//     };

//     var array: [*c]php.zval = undefined;
//     parse_arg_array(&diag, &func, 1, &array, &.{ php.PhpType.Array, php.PhpType.Object }) catch |err| {
//         diag.report(err);
//         return;
//     };

//     php.set_zval_long(return_value, php.zend_hash_num_elements(php.Z_ARRVAL_P(array)));
// }

pub export fn php_count_recursive(arg_ht: [*c]php.HashTable) php.zend_long {
    var ht = arg_ht;
    _ = &ht;
    var cnt: php.zend_long = 0;
    _ = &cnt;
    var element: [*c]php.zval = undefined;
    _ = &element;
    if (!((php.zval_gc_flags(ht.*.gc.u.type_info) & @as(u32, @bitCast(@as(c_int, 1) << @intCast(6)))) != 0)) {
        if ((php.zval_gc_flags(ht.*.gc.u.type_info) & @as(u32, @bitCast(@as(c_int, 1) << @intCast(5)))) != 0) {
            php.php_error_docref(null, @as(c_int, 1) << @intCast(1), "Recursion detected");
            return 0;
        }
        while (true) {
            while (true) {
                ht.*.gc.u.type_info |= @as(u32, @bitCast((@as(c_int, 1) << @intCast(5)) << @intCast(0)));
                if (!false) break;
            }
            if (!false) break;
        }
    }
    cnt = @as(php.zend_long, @bitCast(@as(c_ulonglong, php.zend_hash_num_elements(ht))));
    while (true) {
        var __ht: [*c]const php.HashTable = ht;
        _ = &__ht;
        var _count: u32 = __ht.*.nNumUsed;
        _ = &_count;
        var _size: usize = @sizeOf(php.zval) +% (@as(c_ulong, @bitCast(@as(c_ulong, ~__ht.*.u.flags & @as(u32, @bitCast(@as(c_int, 1) << @intCast(2)))))) *% ((@sizeOf(php.Bucket) -% @sizeOf(php.zval)) / @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1) << @intCast(2))))));
        _ = &_size;
        var _z: [*c]php.zval = __ht.*.unnamed_0.arPacked;
        _ = &_z;
        while (_count > @as(u32, @bitCast(@as(c_int, 0)))) : (_ = blk: {
            _z = @as([*c]php.zval, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(_z))) + _size)));
            break :blk blk_1: {
                const ref = &_count;
                const tmp = ref.*;
                ref.* -%= 1;
                break :blk_1 tmp;
            };
        }) {
            if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_z.*)))) == @as(c_int, 0)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) continue;
            element = _z;
            {
                while (true) {
                    if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&element.*)))) == @as(c_int, 10)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
                        element = &element.*.value.ref.*.val;
                    }
                    if (!false) break;
                }
                if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&element.*)))) == @as(c_int, 7)) {
                    cnt += php_count_recursive(element.*.value.arr);
                }
            }
        }
        if (!false) break;
    }
    while (true) {
        if (!((php.zval_gc_flags(ht.*.gc.u.type_info) & @as(u32, @bitCast(@as(c_int, 1) << @intCast(6)))) != 0)) while (true) {
            while (true) {
                ht.*.gc.u.type_info &= @as(u32, @bitCast(~((@as(c_int, 1) << @intCast(5)) << @intCast(0))));
                if (!false) break;
            }
            if (!false) break;
        };
        if (!false) break;
    }
    return cnt;
}

pub export fn zif_arr_count(arg_execute_data: [*c]php.zend_execute_data, arg_return_value: [*c]php.zval) void {
    var execute_data = arg_execute_data;
    _ = &execute_data;
    var return_value = arg_return_value;
    _ = &return_value;
    var array: [*c]php.zval = undefined;
    _ = &array;
    var mode: php.zend_long = 0;
    _ = &mode;
    var cnt: php.zend_long = undefined;
    _ = &cnt;
    while (true) {
        const _flags: c_int = @as(c_int, 0);
        _ = &_flags;
        var _min_num_args: u32 = @as(u32, @bitCast(@as(c_int, 1)));
        _ = &_min_num_args;
        var _max_num_args: u32 = @as(u32, @bitCast(@as(c_int, 2)));
        _ = &_max_num_args;
        var _num_args: u32 = execute_data.*.This.u2.num_args;
        _ = &_num_args;
        var _i: u32 = 0;
        _ = &_i;
        var _real_arg: [*c]php.zval = undefined;
        _ = &_real_arg;
        var _arg: [*c]php.zval = null;
        _ = &_arg;
        var _expected_type: php.zend_expected_type = @as(c_uint, @bitCast(php.Z_EXPECTED_LONG));
        _ = &_expected_type;
        var _error: [*c]u8 = null;
        _ = &_error;
        var _dummy: bool = @as(c_int, 0) != 0;
        _ = &_dummy;
        var _optional: bool = @as(c_int, 0) != 0;
        _ = &_optional;
        var _error_code: c_int = 0;
        _ = &_error_code;
        _ = &_i;
        _ = &_real_arg;
        _ = &_arg;
        _ = &_expected_type;
        _ = &_error;
        _ = &_optional;
        _ = &_dummy;
        while (true) {
            if ((__builtin_expect(@as(c_long, @intFromBool(!!(_num_args < _min_num_args))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) or (__builtin_expect(@as(c_long, @intFromBool(!!(_num_args > _max_num_args))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0)) {
                if (!((_flags & (@as(c_int, 1) << @intCast(1))) != 0)) {
                    php.zend_wrong_parameters_count_error(_min_num_args, _max_num_args);
                }
                _error_code = 1;
                break;
            }
            _real_arg = @as([*c]php.zval, @ptrCast(@alignCast(execute_data))) + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(c_uint, @truncate(((@sizeOf(php.zend_execute_data) +% @sizeOf(php.zval)) -% @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 1))))) / @sizeOf(php.zval))))) + (@as(c_int, 0) - @as(c_int, 1))))));
            _i +%= 1;
            __builtin_assume((_i <= _min_num_args) or (@as(c_int, @intFromBool(_optional)) == @as(c_int, 1)));
            __builtin_assume((_i > _min_num_args) or (@as(c_int, @intFromBool(_optional)) == @as(c_int, 0)));
            if (_optional) {
                if (__builtin_expect(@as(c_long, @intFromBool(!!(_i > _num_args))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) break;
            }
            _real_arg += 1;
            _arg = _real_arg;
            if (false) {
                if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_arg.*)))) == @as(c_int, 10)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) {
                    _arg = &_arg.*.value.ref.*.val;
                }
            }
            if (false) {
                while (true) {
                    var _zv: [*c]php.zval = _arg;
                    _ = &_zv;
                    __builtin_assume(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_zv.*)))) != @as(c_int, 10));
                    if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_zv.*)))) == @as(c_int, 7)) {
                        while (true) {
                            var __zv: [*c]php.zval = _zv;
                            _ = &__zv;
                            var _arr: [*c]php.zend_array = __zv.*.value.arr;
                            _ = &_arr;
                            if (__builtin_expect(@as(c_long, @intFromBool(!!(php.zend_gc_refcount(&_arr.*.gc) > @as(u32, @bitCast(@as(c_int, 1)))))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
                                while (true) {
                                    var __arr: [*c]php.zend_array = php.zend_array_dup(_arr);
                                    _ = &__arr;
                                    var __z: [*c]php.zval = __zv;
                                    _ = &__z;
                                    __z.*.value.arr = __arr;
                                    __z.*.u1.type_info = @as(u32, @bitCast((@as(c_int, 7) | ((@as(c_int, 1) << @intCast(0)) << @intCast(8))) | ((@as(c_int, 1) << @intCast(1)) << @intCast(8))));
                                    if (!false) break;
                                }
                                php.zend_gc_try_delref(&_arr.*.gc);
                            }
                            if (!false) break;
                        }
                    }
                    if (!false) break;
                }
            }
            php.zend_parse_arg_zval_deref(_arg, &array, @as(c_int, 0) != 0);
            _optional = @as(c_int, 1) != 0;
            _i +%= 1;
            __builtin_assume((_i <= _min_num_args) or (@as(c_int, @intFromBool(_optional)) == @as(c_int, 1)));
            __builtin_assume((_i > _min_num_args) or (@as(c_int, @intFromBool(_optional)) == @as(c_int, 0)));
            if (_optional) {
                if (__builtin_expect(@as(c_long, @intFromBool(!!(_i > _num_args))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) break;
            }
            _real_arg += 1;
            _arg = _real_arg;
            if (false) {
                if (__builtin_expect(@as(c_long, @intFromBool(!!(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_arg.*)))) == @as(c_int, 10)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 1))))) != 0) {
                    _arg = &_arg.*.value.ref.*.val;
                }
            }
            if (false) {
                while (true) {
                    var _zv: [*c]php.zval = _arg;
                    _ = &_zv;
                    __builtin_assume(@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_zv.*)))) != @as(c_int, 10));
                    if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&_zv.*)))) == @as(c_int, 7)) {
                        while (true) {
                            var __zv: [*c]php.zval = _zv;
                            _ = &__zv;
                            var _arr: [*c]php.zend_array = __zv.*.value.arr;
                            _ = &_arr;
                            if (__builtin_expect(@as(c_long, @intFromBool(!!(php.zend_gc_refcount(&_arr.*.gc) > @as(u32, @bitCast(@as(c_int, 1)))))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
                                while (true) {
                                    var __arr: [*c]php.zend_array = php.zend_array_dup(_arr);
                                    _ = &__arr;
                                    var __z: [*c]php.zval = __zv;
                                    _ = &__z;
                                    __z.*.value.arr = __arr;
                                    __z.*.u1.type_info = @as(u32, @bitCast((@as(c_int, 7) | ((@as(c_int, 1) << @intCast(0)) << @intCast(8))) | ((@as(c_int, 1) << @intCast(1)) << @intCast(8))));
                                    if (!false) break;
                                }
                                php.zend_gc_try_delref(&_arr.*.gc);
                            }
                            if (!false) break;
                        }
                    }
                    if (!false) break;
                }
            }
            if (__builtin_expect(@as(c_long, @intFromBool(!!!php.zend_parse_arg_long(_arg, &mode, &_dummy, @as(c_int, 0) != 0, _i))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
                _expected_type = @as(c_uint, @bitCast(if (false) php.Z_EXPECTED_LONG_OR_NULL else php.Z_EXPECTED_LONG));
                _error_code = 9;
                break;
            }
            __builtin_assume((_i == _max_num_args) or (_max_num_args == @as(u32, @bitCast(-@as(c_int, 1)))));
            if (!false) break;
        }
        if (__builtin_expect(@as(c_long, @intFromBool(!!(_error_code != @as(c_int, 0)))), @as(c_long, @bitCast(@as(c_long, @as(c_int, 0))))) != 0) {
            if (!((_flags & (@as(c_int, 1) << @intCast(1))) != 0)) {
                php.zend_wrong_parameter_error(_error_code, _i, _error, _expected_type, _arg);
            }
            return;
        }
        if (!false) break;
    }
    if ((mode != @as(php.zend_long, @bitCast(@as(c_longlong, @as(c_int, 0))))) and (mode != @as(php.zend_long, @bitCast(@as(c_longlong, @as(c_int, 1)))))) {
        php.zend_argument_value_error(@as(u32, @bitCast(@as(c_int, 2))), "must be either COUNT_NORMAL or COUNT_RECURSIVE");
        while (true) {
            __builtin_assume(@intFromPtr(php.executor_globals.exception) != 0);
            _ = &return_value;
            return;
        }
    }
    while (true) {
        switch (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&array.*))))) {
            @as(c_int, 7) => {
                if (mode != @as(php.zend_long, @bitCast(@as(c_longlong, @as(c_int, 1))))) {
                  cnt = @as(php.zend_long, @bitCast(@as(c_ulonglong, php.zend_hash_num_elements(array.*.value.arr))));
                } else {
                    cnt = php_count_recursive(array.*.value.arr);
                }
                while (true) {
                    while (true) {
                        var __z: [*c]php.zval = return_value;
                        _ = &__z;
                        __z.*.value.lval = cnt;
                        __z.*.u1.type_info = 4;
                        if (!false) break;
                    }
                    return;
                }
                break;
            },
            @as(c_int, 8) => {
                {
                    var retval: php.zval = undefined;
                    _ = &retval;
                    var zobj: [*c]php.zend_object = array.*.value.obj;
                    _ = &zobj;
                    if (zobj.*.handlers.*.count_elements != null) {
                        while (true) {
                            var __z: [*c]php.zval = return_value;
                            _ = &__z;
                            __z.*.value.lval = 1;
                            __z.*.u1.type_info = 4;
                            if (!false) break;
                        }
                        if (php.SUCCESS == zobj.*.handlers.*.count_elements.?(zobj, &return_value.*.value.lval)) {
                            return;
                        }
                        if (php.executor_globals.exception != null) {
                            while (true) {
                                __builtin_assume(@intFromPtr(php.executor_globals.exception) != 0);
                                _ = &return_value;
                                return;
                            }
                        }
                    }
                    if (php.instanceof_function(zobj.*.ce, zend_ce_countable)) {
                        var count_fn: [*c]php.zend_function = @as([*c]php.zend_function, @ptrCast(@alignCast(php.zend_hash_find_ptr(&zobj.*.ce.*.function_table, (blk: {
                            const tmp = php.ZEND_STR_COUNT;
                            if (tmp >= 0) break :blk php.zend_known_strings + @as(usize, @intCast(tmp)) else break :blk php.zend_known_strings - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))));
                        _ = &count_fn;
                        php.zend_call_known_instance_method_with_0_params(count_fn, zobj, &retval);
                        if (@as(c_int, @bitCast(@as(c_uint, php.zval_get_type(&retval)))) != @as(c_int, 0)) {
                            while (true) {
                                var __z: [*c]php.zval = return_value;
                                _ = &__z;
                                __z.*.value.lval = php_get_long(&retval);
                                __z.*.u1.type_info = 4;
                                if (!false) break;
                            }
                        }
                        return;
                    }
                }
                _ = @as(c_int, 0);
                php.zend_argument_type_error(@as(u32, @bitCast(@as(c_int, 1))), "must be of type Countable|array, %s given", php.zend_zval_value_name(array));
                while (true) {
                    __builtin_assume(@intFromPtr(php.executor_globals.exception) != 0);
                    _ = &return_value;
                    return;
                }
            },
            else => {
                php.zend_argument_type_error(@as(u32, @bitCast(@as(c_int, 1))), "must be of type Countable|array, %s given", php.zend_zval_value_name(array));
                while (true) {
                    __builtin_assume(@intFromPtr(php.executor_globals.exception) != 0);
                    _ = &return_value;
                    return;
                }
            },
        }
        break;
    }
}
