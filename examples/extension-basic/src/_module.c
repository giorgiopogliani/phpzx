#include "zend_API.h"
#include "zend_types.h"
#include <php.h>

extern void zif_arr_count(zend_execute_data *execute_data, zval *return_value);
ZEND_BEGIN_ARG_INFO(arginfo_arr_count, 0)
ZEND_ARG_ARRAY_INFO(0, array, 0)
ZEND_END_ARG_INFO()

// Define the function entry for the PHP extension
static const zend_function_entry server_functions[] = {
    PHP_FE(arr_count, arginfo_arr_count)
    PHP_FE_END
};

// Define the module entry
zend_module_entry myext_module_entry = {STANDARD_MODULE_HEADER,
                                        "myext",          // Module name
                                        server_functions, // Functions
                                        NULL,             // MINIT
                                        NULL,             // MSHUTDOWN
                                        NULL,             // RINIT
                                        NULL,             // RSHUTDOWN
                                        NULL,             // MINFO
                                        "1.0",            // Version
                                        STANDARD_MODULE_PROPERTIES};

// Implement the get_module function
ZEND_GET_MODULE(myext)
