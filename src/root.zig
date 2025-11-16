const std = @import("std");
pub const c = @import("include.zig").c;

pub const PhpModuleBuilder = @import("module.zig").PhpModuleBuilder;
const functions = @import("functions.zig");
pub const PhpFunctionArg = functions.PhpFunctionArg;
pub const PhpFunctionEntry = functions.PhpFunctionEntry;
pub const PhpFunctionArgInfo = functions.PhpFunctionArgInfo;
pub const types = @import("types.zig");
pub const PhpType = types.PhpType;
pub const PhpCallable = types.PhpCallable;
pub const PhpString = types.PhpString;
pub const PhpArray = types.PhpArray;
pub const PhpValue = types.PhpValue;
pub const PhpError = @import("errors.zig").PhpError;
pub const helpers = @import("helpers.zig");

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
