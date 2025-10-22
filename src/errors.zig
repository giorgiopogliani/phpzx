/// Errors codes ported from PHP source code
pub const PhpError = error{
    ErrorFailure, //  1
    ErrorWrongCallback, //  2
    ErrorWrongClass, //  3
    ErrorWrongClassOrNull, //  4
    ErrorWrongClassOrString, //  5
    ErrorWrongClassOrStringOrNull, //  6
    ErrorWrongClassOrLong, //  7
    ErrorWrongClassOrLongOrNull, //  8
    ErrorWrongArg, //  9
    ErrorWrongCount, // 10
    ErrorUnexpectedExtraNamed, // 11
    ErrorWrongCallbackOrNull, // 12
    /// Custom error codes
    ErrorUnexpectedType,
};
