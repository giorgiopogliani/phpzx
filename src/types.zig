const c = @import("include.zig").c;
const PhpDiagnostic = @import("diagnostic.zig").PhpDiagnostic;
const PhpFunctionArg = @import("functions.zig").PhpFunctionArg;
const PhpError = @import("errors.zig").PhpError;

pub const PhpType = enum(u8) {
    Undef = c.IS_UNDEF,
    Null = c.IS_NULL,
    False = c.IS_FALSE,
    True = c.IS_TRUE,
    Long = c.IS_LONG,
    Double = c.IS_DOUBLE,
    String = c.IS_STRING,
    Array = c.IS_ARRAY,
    Object = c.IS_OBJECT,
    Resource = c.IS_RESOURCE,
    Reference = c.IS_REFERENCE,
    ConstantAst = c.IS_CONSTANT_AST,
    Callable = c.IS_CALLABLE,
    Iterable = c.IS_ITERABLE,
    Void = c.IS_VOID,
    Static = c.IS_STATIC,
    Mixed = c.IS_MIXED,
    Never = c.IS_NEVER
};

/// Wrapper for PHP callable/closure that combines fci and fci_cache
pub const PhpCallable = struct {
    fci: c.zend_fcall_info,
    fci_cache: c.zend_fcall_info_cache,

    /// Call this callable with no arguments
    pub fn call(self: *PhpCallable, retval: *c.zval) !void {
        // Set up the return value
        self.fci.retval = retval;
        self.fci.param_count = 0;
        self.fci.params = null;

        // Call the function
        const result = c.zend_call_function(&self.fci, &self.fci_cache);
        if (result != c.SUCCESS) {
            return error.CallFailed;
        }
    }

    /// Call this callable with arguments
    pub fn callWithArgs(self: *PhpCallable, retval: [*c]c.zval, params: [*c]c.zval, param_count: u32) !void {
        // Set up the return value and parameters
        self.fci.retval = retval;
        self.fci.params = params;
        self.fci.param_count = param_count;

        // Call the function
        const result = c.zend_call_function(&self.fci, &self.fci_cache);
        if (result != c.SUCCESS) {
            return error.CallFailed;
        }
    }

    /// Call this callable with one argument and return the result
    pub fn callAndReturn(self: *const PhpCallable, arg: [*]c.zval) !c.zval {
        var retval: c.zval = undefined;

        // Use the working callWithArgs method internally
        var mutable_self = PhpCallable{
            .fci = self.fci,
            .fci_cache = self.fci_cache,
        };

        try mutable_self.callWithArgs(&retval, arg, 1);
        return retval;
    }
};

/// Wrapper for PHP string
pub const PhpString = struct {
    ptr: [*c]u8,
    len: usize,

    pub fn asSlice(self: PhpString) []u8 {
        return self.ptr[0..self.len];
    }
};

/// Wrapper for PHP array with convenient iteration methods
pub const PhpArray = struct {
    table: *c.HashTable,
    current: [*]c.zval,
    end: [*]c.zval,
    index: c_uint,

    pub inline fn new(php_val: *c.zval, size: u32) PhpArray {
        // Manually initialize array without using array_init_size
        const table = c.zend_new_array(size);
        php_val.*.value.arr = table;
        php_val.*.u1.type_info = @intFromEnum(PhpType.Array);

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

    pub inline fn next(self: *PhpArray) [*]c.zval {
        self.current += 1;
        self.index +%= 1;
        return self.current;
    }

    pub inline fn count(self: *const PhpArray) usize {
        return self.table.nNumOfElements;
    }

    pub inline fn fill(self: *PhpArray, result: c.zval) void {
        // Create a proper zval copy using PHP's memory management
        var zval_copy: c.zval = undefined;
        zval_copy = result;

        // Add reference if it's a refcounted type
        const is_refcounted = (result.u1.type_info & 0xff00) != 0;
        if (is_refcounted and result.value.counted != null) {
            _ = c.GC_ADDREF(result.value.counted);
        }

        // Use proper PHP API to add element to array
        _ = c.zend_hash_next_index_insert(self.table, &zval_copy);
    }

    pub inline fn reset(self: *PhpArray) void {
        self.current = self.table.unnamed_0.arPacked;
        self.index = 0;
    }

    // Helper to finalize hashtable
    pub inline fn finalize(self: *PhpArray) void {
        if (self.index >= self.table.*.nNumUsed) {
            self.table.*.nNumOfElements += self.index - self.table.*.nNumUsed;
        }
        self.table.*.nNumUsed = self.index;
        self.table.*.nNextFreeElement = @as(c.zend_long, @bitCast(@as(c_ulonglong, self.index)));
        self.table.*.nInternalPointer = 0;
    }

    pub inline fn destroy(self: *PhpArray) void {
        c.zend_array_destroy(self.table);
    }
};

/// General wrapper for PHP zval with convenient methods
pub const PhpValue = struct {
    zval: *c.zval,

    /// Create a PhpValue wrapper from a zval pointer
    pub fn init(zval_ptr: *c.zval) PhpValue {
        return PhpValue{ .zval = zval_ptr };
    }

    /// Get array hash table pointer
    pub fn getArrayHashTable(self: PhpValue) ?*c.HashTable {
        if (self.isArray()) {
            return c.Z_ARRVAL_P(self.zval);
        }
        return null;
    }

    /// Get array as PhpArray wrapper
    pub fn asPhpArray(self: PhpValue) ?PhpArray {
        if (self.isArray()) {
            return PhpArray.from(self.zval);
        }
        return null;
    }
};


pub const PhpInt = c.zend_long;
// struct {
//     value: c.zend_long,

//     /// Create a PhpInt wrapper from a zval pointer
//     pub fn init(zval_ptr: *c.zval) PhpInt {
//         return PhpInt{ .value = c.Z_LVAL_P(zval_ptr) };
//     }

//     /// Get integer value
//     pub fn get(self: PhpInt) c.zend_long {
//         return self.value;
//     }

//     pub fn parse(diag: *PhpDiagnostic, data: PhpFunctionArg, arg_index: usize) PhpError!PhpInt {
//       _ = diag;
//       return PhpInt{ .value = c.zval_get_long(data.args + arg_index + 1) };
//
//     }
// };
