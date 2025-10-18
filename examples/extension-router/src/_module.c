#include <php.h>

typedef struct _sample_obj {
    zend_long value;
    zend_object std;
} sample_obj;

static zend_class_entry *sample_ce;
static zend_object_handlers sample_handlers;

static zend_object *sample_create_obj(zend_class_entry *ce) {
    sample_obj *obj = zend_object_alloc(sizeof(sample_obj), ce);
    zend_object_std_init(&obj->std, ce);
    object_properties_init(&obj->std, ce);
    obj->std.handlers = &sample_handlers;
    return &obj->std;
}

ZEND_BEGIN_ARG_INFO_EX(arginfo_sample_construct, 0, 0, 1)
    ZEND_ARG_TYPE_INFO(0, value, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO_EX(arginfo_sample_getValue, 0, 0, 0)
ZEND_END_ARG_INFO()

PHP_METHOD(Sample, __construct) {
    zend_long val = 0;
    ZEND_PARSE_PARAMETERS_START(1, 1)
        Z_PARAM_LONG(val)
    ZEND_PARSE_PARAMETERS_END();
    sample_obj *obj = Z_PTR_P(ZEND_THIS);
    ((sample_obj*)((char*)obj - XtOffsetOf(sample_obj, std)))->value = val;
}

PHP_METHOD(Sample, getValue) {
    sample_obj *obj = Z_PTR_P(ZEND_THIS);
    RETURN_LONG(((sample_obj*)((char*)obj - XtOffsetOf(sample_obj, std)))->value);
}

static const zend_function_entry sample_methods[] = {
    PHP_ME(Sample, __construct, arginfo_sample_construct, ZEND_ACC_PUBLIC|ZEND_ACC_CTOR)
    PHP_ME(Sample, getValue, arginfo_sample_getValue, ZEND_ACC_PUBLIC)
    PHP_FE_END
};

PHP_MINIT_FUNCTION(sample) {
    zend_class_entry ce;
    INIT_CLASS_ENTRY(ce, "Sample", sample_methods);
    sample_ce = zend_register_internal_class(&ce);
    sample_ce->create_object = sample_create_obj;
    memcpy(&sample_handlers, zend_get_std_object_handlers(), sizeof(zend_object_handlers));
    return SUCCESS;
}

zend_module_entry sample_module_entry = {
    STANDARD_MODULE_HEADER,
    "sample",
    NULL,
    PHP_MINIT(sample),
    NULL,
    NULL,
    NULL,
    NULL,
    NO_VERSION_YET,
    STANDARD_MODULE_PROPERTIES
};

ZEND_GET_MODULE(sample)
