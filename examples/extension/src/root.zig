// Import and ensure the function is included in compilation
const arr_map = @import("arr_map.zig");
comptime {
    _ = arr_map.zif_arr_map;
}
