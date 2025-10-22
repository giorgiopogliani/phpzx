const c = @import("include.zig").c;

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
    pub fn call(self: *PhpCallable, retval: [*c]c.zval) !void {
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
};

/// Wrapper for PHP string
pub const PhpString = struct {
    ptr: [*c]u8,
    len: usize,
    
    pub fn asSlice(self: PhpString) []u8 {
        return self.ptr[0..self.len];
    }
};
