const std = @import("std");
pub const c = @import("include.zig").c;

pub const PhpModuleBuilder = @import("module.zig").PhpModuleBuilder;
const functions = @import("functions.zig");
pub const PhpFunctionArg = functions.PhpFunctionArg;
pub const PhpFunctionEntry = functions.PhpFunctionEntry;
pub const PhpFunctionArgInfo = functions.PhpFunctionArgInfo;
const types = @import("types.zig");
pub const PhpType = types.PhpType;
pub const PhpCallable = types.PhpCallable;
pub const PhpString = types.PhpString;
pub const PhpError = @import("errors.zig").PhpError;

// Class helpers
const classes = @import("classes.zig");
pub const getThisObject = classes.getThisObject;
pub const initClassEntry = classes.initClassEntry;
pub const registerClass = classes.registerClass;
pub const copyStdHandlers = classes.copyStdHandlers;
pub const createObjectHandler = classes.createObjectHandler;
pub const PhpClassBuilder = classes.PhpClassBuilder; // Legacy API
pub const PhpClass = classes.PhpClass; // New simplified API
pub const registerClasses = classes.registerClasses; // Multi-class registration

/// Expected type enums
pub const PhpExpectedType = enum(c_int) {
    Long = c.Z_EXPECTED_LONG,
    LongOrNull = c.Z_EXPECTED_LONG_OR_NULL,
    Bool = c.Z_EXPECTED_BOOL,
    BoolOrNull = c.Z_EXPECTED_BOOL_OR_NULL,
    String = c.Z_EXPECTED_STRING,
    StringOrNull = c.Z_EXPECTED_STRING_OR_NULL,
    Array = c.Z_EXPECTED_ARRAY,
    ArrayOrNull = c.Z_EXPECTED_ARRAY_OR_NULL,
    ArrayOrLong = c.Z_EXPECTED_ARRAY_OR_LONG,
    ArrayOrLongOrNull = c.Z_EXPECTED_ARRAY_OR_LONG_OR_NULL,
    Iterable = c.Z_EXPECTED_ITERABLE,
    IterableOrNull = c.Z_EXPECTED_ITERABLE_OR_NULL,
    Func = c.Z_EXPECTED_FUNC,
    FuncOrNull = c.Z_EXPECTED_FUNC_OR_NULL,
    Resource = c.Z_EXPECTED_RESOURCE,
    ResourceOrNull = c.Z_EXPECTED_RESOURCE_OR_NULL,
    Path = c.Z_EXPECTED_PATH,
    PathOrNull = c.Z_EXPECTED_PATH_OR_NULL,
    Object = c.Z_EXPECTED_OBJECT,
    ObjectOrNull = c.Z_EXPECTED_OBJECT_OR_NULL,
    Double = c.Z_EXPECTED_DOUBLE,
    DoubleOrNull = c.Z_EXPECTED_DOUBLE_OR_NULL,
    Number = c.Z_EXPECTED_NUMBER,
    NumberOrNull = c.Z_EXPECTED_NUMBER_OR_NULL,
    NumberOrString = c.Z_EXPECTED_NUMBER_OR_STRING,
    NumberOrStringOrNull = c.Z_EXPECTED_NUMBER_OR_STRING_OR_NULL,
    ArrayOrString = c.Z_EXPECTED_ARRAY_OR_STRING,
    ArrayOrStringOrNull = c.Z_EXPECTED_ARRAY_OR_STRING_OR_NULL,
    StringOrLong = c.Z_EXPECTED_STRING_OR_LONG,
    StringOrLongOrNull = c.Z_EXPECTED_STRING_OR_LONG_OR_NULL,
    ObjectOrClassName = c.Z_EXPECTED_OBJECT_OR_CLASS_NAME,
    ObjectOrClassNameOrNull = c.Z_EXPECTED_OBJECT_OR_CLASS_NAME_OR_NULL,
    ObjectOrString = c.Z_EXPECTED_OBJECT_OR_STRING,
    ObjectOrStringOrNull = c.Z_EXPECTED_OBJECT_OR_STRING_OR_NULL,
    Last = c.Z_EXPECTED_LAST,
};

/// Php array wrapper
// Simple iterator for PHP HashTable
pub const PhpArray = struct {
    table: *c.HashTable,
    current: [*c]c.zval,
    end: [*c]c.zval,
    index: c_uint,

    pub inline fn new(php_val: *c.zval, size: u32) PhpArray {
        c.array_init_size(php_val, size);
        const table = c.Z_ARRVAL_P(php_val);
        c.zend_hash_real_init_packed(table);

        return PhpArray{
            .table = table,
            .current = table.*.unnamed_0.arPacked,
            .end = table.*.unnamed_0.arPacked + table.*.nNumUsed,
            .index = table.*.nNumUsed,
        };
    }

    pub inline fn from(php_val: [*c]c.zval) PhpArray {
        const table = c.Z_ARRVAL_P(php_val);
        return PhpArray{
            .table = table,
            .current = table.*.unnamed_0.arPacked,
            .end = table.*.unnamed_0.arPacked + table.*.nNumUsed,
            .index = table.*.nNumUsed,
        };
    }

    pub inline fn hasNext(self: *const PhpArray) bool {
        return self.current != self.end;
    }

    pub inline fn next(self: *PhpArray) *c.zval {
        self.current += 1;
        self.index +%= 1;
        return self.current;
    }

    pub inline fn fill(self: *PhpArray, result: [*c]c.zval) void {
        const _z1: [*c]c.zval = self.current;
        const _z2: [*c]const c.zval = result;
        const _gc: [*c]c.zend_refcounted = _z2.*.value.counted;
        const _t: u32 = _z2.*.u1.type_info;
        _z1.*.value.counted = _gc;
        _z1.*.u1.type_info = _t;
        self.current += 1;
        self.index +%= 1;
    }

    pub inline fn reset(self: *PhpArray) void {
        self.current = self.table.unnamed_0.arPacked;
        self.index = 0;
    }

    // Helper to finalize hashtable
    pub inline fn finalize(self: *PhpArray) void {
        self.table.*.nNumOfElements +%= self.index - self.table.nNumUsed;
        self.table.*.nNumUsed = self.index;
        self.table.*.nNextFreeElement = @as(c.zend_long, @bitCast(@as(c_ulonglong, self.index)));
        self.table.*.nInternalPointer = 0;
    }

    pub inline fn destroy(self: *PhpArray) void {
        c.zend_array_destroy(self.table);
    }
};
