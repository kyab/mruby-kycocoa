#include <stdio.h>

#include "mruby.h"
#include "mruby/string.h"
#include "mruby/variable.h"
#include "mruby/class.h"
#include "mruby/array.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <objc/objc.h>
#import <Foundation/Foundation.h>

#include <limits.h>
#include "ffi.h"

typedef void (*func_type)(void);


mrb_bool mrb_objc_id_p(mrb_state *mrb, mrb_value rval){
	struct RClass *kycocoa_module = mrb_class_get(mrb, "KYCocoa");
	struct RClass *cocoa_proxy_class = mrb_class_get_under(mrb,kycocoa_module, "CocoaProxy");


	return (mrb_obj_is_kind_of(mrb, rval, cocoa_proxy_class));
}

//create new KYCocoa::CocoaProxy instance from Objective-c id
mrb_value objc_id_value(mrb_state *mrb, id objc_id){
	struct RClass *kycocoa_module = mrb_class_get(mrb, "KYCocoa");
	struct RClass *cocoa_proxy_class = mrb_class_get_under(mrb, kycocoa_module,"CocoaProxy");

	mrb_value rval_obj = mrb_class_new_instance(mrb, 0, NULL, cocoa_proxy_class);

	mrb_iv_set(mrb, rval_obj, mrb_intern_cstr(mrb, "@objc_id"), mrb_voidp_value(mrb, objc_id) );

	{
		mrb_value rval_id = mrb_iv_get(mrb, rval_obj, mrb_intern_cstr(mrb, "@objc_id"));
		if (objc_id != (id)mrb_voidp(rval_id)){
			printf("@obj_id mismatch!\n");
		}

		if (!mrb_objc_id_p(mrb, rval_obj)){
			printf("not objc_id! ??\n");
		}
	}
	if (class_isMetaClass(object_getClass(objc_id))){
		//class object.
		printf("New Proxy from id = %p, class:Class(%s)\n", 
			objc_id, object_getClassName(objc_id));	//object_getClassName for class object still return non-meta name. 
	}else{
		printf("New Proxy from id = %p, class:%s\n", objc_id, object_getClassName(objc_id) );
	}
	return rval_obj;
}



id objc_id(mrb_state *mrb, mrb_value rval){
	mrb_value rval_id = mrb_iv_get(mrb, rval, mrb_intern_cstr(mrb, "@objc_id"));
	return (id)mrb_voidp(rval_id);
}

mrb_value kycocoa_objc_id(mrb_state *mrb, mrb_value self){
	id objc_id_ = objc_id(mrb, self);

	//Fixnum is int so not enough..
	return mrb_float_value(mrb, (unsigned long)objc_id_);
}

mrb_value kycocoa_objc_id_hex(mrb_state *mrb, mrb_value self){
	id objc_id_ = objc_id(mrb, self);
	char hex_str[20];
	sprintf(hex_str,"%p",objc_id_);
	return mrb_str_new_cstr(mrb, hex_str);
}

// mrb_value kycocoa_proxy_from_id(mrb_state *mrb, mrb_value self){
// 	mrb_value rval_id;
// 	mrb_get_args(mrb, "i", &rval_id);

// }

#define IF_TYPE_SELECT(encoding,pfunc,mes,ffitype) \
		if (0 == strcmp(arg_type_enc,(encoding))){ \
			if (!pfunc(rvalue)) mrb_raisef(mrb, E_ARGUMENT_ERROR, mes ); \
			*pp_type = &ffitype;


//TODO: separate type conversion and value conversion
static void *convert_rvalue_to_ffi(const char *arg_type_enc, mrb_state *mrb, mrb_value rvalue, ffi_type **pp_type){
	void *pval = NULL;

	printf("in convert_rvalue_to_ffi, arg_type_enc = %s\n", arg_type_enc);
	IF_TYPE_SELECT("c",mrb_fixnum_p,"char!",ffi_type_schar){

		//I Assume char is signed but may not work with ARM
		//http://d.hatena.ne.jp/yohhoy/20130314/p1
		pval = malloc(sizeof(char));
		*((char *)pval) = mrb_fixnum(rvalue);
	}}
	
	else IF_TYPE_SELECT("i", mrb_fixnum_p, "int!", ffi_type_sint){
		pval = malloc(sizeof(int));
		*((int *)pval) = mrb_fixnum(rvalue);
	}}
	
	else IF_TYPE_SELECT("s", mrb_fixnum_p, "short!", ffi_type_sshort){
		pval = malloc(sizeof(short));
		*((short *)pval) = mrb_fixnum(rvalue);
	}}

	else IF_TYPE_SELECT("l", mrb_fixnum_p, "long!", ffi_type_slong){
		pval = malloc(sizeof(long));
		*((long *)pval) = mrb_fixnum(rvalue);
	}}
	else IF_TYPE_SELECT("q", mrb_fixnum_p, "long long!", ffi_type_sint64){
		pval = malloc(sizeof(long long));
		*((long long*)pval) = mrb_fixnum(rvalue);
	}}

	else IF_TYPE_SELECT("C", mrb_fixnum_p, "unsigned char!", ffi_type_uchar){
		pval = malloc(sizeof(unsigned char));
		*((unsigned char *)pval) = mrb_fixnum(rvalue);
	}}
	else IF_TYPE_SELECT("I", mrb_fixnum_p, "unsigned int!", ffi_type_uint){
		pval = malloc(sizeof(unsigned int));
		*((unsigned int*)pval) = mrb_fixnum(rvalue);
	}}
	else IF_TYPE_SELECT("S", mrb_fixnum_p, "unsigned short!", ffi_type_ushort){
		pval = malloc(sizeof(unsigned short));
		*((unsigned short *)pval) = mrb_fixnum(rvalue);
	}}
	else IF_TYPE_SELECT("L", mrb_fixnum_p, "unsigned long!", ffi_type_ulong){
		pval = malloc(sizeof(unsigned long));
		*((unsigned long *)pval) = mrb_fixnum(rvalue);		
	}}
	else IF_TYPE_SELECT("Q", mrb_fixnum_p, "unsigned long long!", ffi_type_uint64){
		if (mrb_nil_p(rvalue)) return NULL;
		pval = malloc(sizeof(unsigned long long));
		*((unsigned long long*)pval) = mrb_fixnum(rvalue);				
	}}
	else IF_TYPE_SELECT("f", mrb_float_p, "float!", ffi_type_float){
		pval = malloc(sizeof(float));
		*((float *)pval) = mrb_float(rvalue);		
	}}
	else IF_TYPE_SELECT("d", mrb_float_p, "double!", ffi_type_double){
		pval = malloc(sizeof(double));
		*((double *)pval) = mrb_float(rvalue);		
	}}
	// else if (0 == strcmp(arg_type_enc,"*")){
	// 	*pptype = &ffi_type_pointer;
	// 	if (mrb_string_p(rvalue)){
	// 		pval = RSTRING_PTR(rvalue);		//hope to const
	// 	}else if (mrb_kycocoa_pointer_p(rvalue)){
	// 		pval = mrb_kycocoa_pointer(rvalue);
	// 	}else{
	// 		mrb_raisef(mrb, E_ARGUMENT_ERROR, "String or Pointer required" )
	// 	}
	// }
	else if ( 0 == strcmp(arg_type_enc, "@")){
		printf("type encoding : @ detected\n");
		*pp_type = &ffi_type_pointer;
		if (mrb_string_p(rvalue)){
			printf("converting ruby String(%s) to NSString\n", RSTRING_PTR(rvalue));
			pval = malloc(sizeof(id));
			*((id *)pval) = [NSMutableString stringWithUTF8String:RSTRING_PTR(rvalue)];
		}

		// else if (mrb_hash_p(rvalue)){

		// }

		else if (mrb_objc_id_p(mrb, rvalue)){
			pval = malloc(sizeof(id));
			*((id *)pval) = objc_id(mrb, rvalue);
		}else if (mrb_nil_p(rvalue)){
			pval = malloc(sizeof(id));
			*((id *)pval) = NULL;	//nil?
		}else if (mrb_fixnum_p(rvalue)){
			pval = malloc(sizeof(id));
			*((id *)pval) = (id)mrb_fixnum(rvalue);
		}else{
			mrb_raisef(mrb, E_ARGUMENT_ERROR, "Should be id");
		}
	}

	// else IF_TYPE_SELECT("#", mrb_objc_class_p, "#!", ffi_type_pointer){
	// 	pval = malloc(sizeof(id));
	// 	*((id *)pval) = mrb_objc_id(rvalue);		
	// }}

	// else IF_TYPE_SELECT(":", mrb_objc_selector_p, ":!", ffi_type_pointer){
	// 	*((SEL *)pval) = mrb_objc_sel(rvalue);
	// }}
	else {
		printf("unsupported type encoding = %s\n", arg_type_enc);
	}

	return pval;
}

mrb_value convert_ffi_ret_to_rvalue(ffi_type *ffi_ret_type/*not required*/, void *ffi_ret_val, 
							const char *objc_ret_type, mrb_state *mrb){
	if (0 == strcmp(objc_ret_type, "@")){
		if (ffi_ret_val == NULL){
			return mrb_nil_value();
		}else{
			return objc_id_value(mrb, (id)ffi_ret_val);
		}

	}else if (0 == strcmp(objc_ret_type, "Q")){
		unsigned long long val = (unsigned long long)ffi_ret_val;
		if (val <= MRB_INT_MAX){
			return mrb_fixnum_value(val);
		}else{
			return mrb_float_value(mrb,val);
		}

	}
	return mrb_nil_value();
}

mrb_value kycocoa_do_objc_msgSend(mrb_state *mrb, mrb_value self){

	printf("kycocoa_do_objc_msgSend\n");
	mrb_value rval_selector;
	mrb_value rval_args;

	mrb_get_args(mrb,"SA", &rval_selector, &rval_args);
	printf("args_num = %d\n",mrb_fixnum(mrb_funcall(mrb,rval_args,"size",0)));

	SEL selector = sel_registerName(RSTRING_PTR(rval_selector));
	printf("selector name = %s\n", sel_getName(selector));

	if (!mrb_objc_id_p(mrb, self)){
		printf("not an objective-C object!\n");
	}

	id objc_self = objc_id(mrb, self);
	
	Class objc_class = object_getClass(objc_self);
	//NSString *instance = [NSString stringWithUTF8String:"Hi Hoo!"];
	Method method;
	if (class_isMetaClass(objc_class)){
		printf("call class method\n");
		method = class_getClassMethod(objc_class, selector);
	}else{
		printf("call instance method\n");
		method = class_getInstanceMethod(objc_class, selector);
	}
	if (!method){
		mrb_raisef(mrb, E_NOMETHOD_ERROR, sel_getName(selector));
	}

	char ret_type[10];
	method_getReturnType(method, ret_type, 10);
	printf("ret type:%s\n",ret_type);

	unsigned arg_num = method_getNumberOfArguments(method);
	char **arg_types= (char **)malloc(arg_num * sizeof(char *));

	//first 2 are receicer and selector.
	for (int i = 0 ; i < arg_num; i++){
		arg_types[i] = (char *)malloc(20 * sizeof(char));
		method_getArgumentType(method, i, arg_types[i],20);
		printf("arg[%d] type = %s\n", i, arg_types[i]);
	}
	

	ffi_cif cif;
	ffi_type *ffi_ret_type;
	void *ffi_ret_val;

	ffi_ret_val = convert_rvalue_to_ffi(ret_type, mrb, mrb_fixnum_value(3), &ffi_ret_type);

	ffi_type **ffi_arg_types = (ffi_type **)malloc(arg_num * sizeof(ffi_type *));
	ffi_arg_types[0] = &ffi_type_pointer;	//receiver
	ffi_arg_types[1] = &ffi_type_pointer;	//selector
	
	void **ffi_arg_vals = malloc(arg_num * sizeof(void *));
	ffi_arg_vals[0] = &objc_self;
	ffi_arg_vals[1] = &selector;

	for (int i = 2; i < arg_num; i++){
		printf("convert r to ffi index = %d\n",i);
		mrb_value rval_arg = mrb_funcall(mrb, rval_args, "at", 1, mrb_fixnum_value(i-2));
		ffi_arg_vals[i] = convert_rvalue_to_ffi(arg_types[i], mrb, rval_arg, &ffi_arg_types[i]);
		if (ffi_arg_vals[i] == NULL){
			mrb_raisef(mrb, E_RUNTIME_ERROR, "failed to call into ffi");
		}
	}

	ffi_status status = ffi_prep_cif_var(&cif,
				FFI_DEFAULT_ABI,
				2,
				arg_num,
				ffi_ret_type,
				ffi_arg_types
				);

	if (status == FFI_OK){
		printf("FFI_OK\n");
	}else{
		printf("FFI_BAD\n");
		mrb_raisef(mrb, E_RUNTIME_ERROR, "failed to call into FFI");
	}

	//id ret;
	ffi_call(&cif, (func_type)objc_msgSend, &ffi_ret_val, ffi_arg_vals);

	if (strcmp(sel_getName(selector),"description") == 0){
		
		return mrb_str_new_cstr(mrb, [(id)ffi_ret_val UTF8String]);
	}

	return convert_ffi_ret_to_rvalue(ffi_ret_type, ffi_ret_val,ret_type, mrb);

}

mrb_value kycocoa_const_missing(mrb_state *mrb, mrb_value self){
	mrb_sym sym;
	mrb_get_args(mrb, "n", &sym);
	const char *name = mrb_sym2name(mrb, sym);
	printf("KYCocoa::const_missing for name : %s\n", name);

	//look up class
	id objc_class_id = objc_lookUpClass(name);
	if (objc_class_id != nil){
		printf("class id = %p\n", objc_class_id);

		mrb_value rval_objc_class = objc_id_value(mrb, objc_class_id);
		//return objc_id_value(mrb, objc_class_id);
		struct RClass *kycocoa_module = mrb_class_get(mrb, "KYCocoa");
		mrb_define_const(mrb, kycocoa_module, name, rval_objc_class );
		return rval_objc_class;
		// struct RClass *cocoa_proxy_class = mrb_class_get_under(mrb, kycocoa_module,"CocoaProxy");
		// struct RClass *objc_class = mrb_define_class_under(mrb, kycocoa_module, name, cocoa_proxy_class );

	}

	mrb_raisef(mrb, E_NAME_ERROR, "%S is not Cocoa Class nor constants", mrb_str_new_cstr(mrb,name));

	return mrb_nil_value();
}

mrb_value get_objc_class_str(mrb_state *mrb, mrb_value self){
	// return mrb_str_new_cstr(mrb, object_getClassName(objc_id(mrb,self)));
	Class objc_class = object_getClass(objc_id(mrb,self));

	if(class_isMetaClass(objc_class)){
		mrb_value ret = mrb_str_new_cstr(mrb, "Class(");
		mrb_str_cat_cstr(mrb, ret, class_getName(objc_class) );
		mrb_str_cat_cstr(mrb, ret, ")");
		return ret;
	}else{
		return mrb_str_new_cstr(mrb, class_getName(objc_class));
	}
}

mrb_value get_objc_class(mrb_state *mrb, mrb_value self){
	// return mrb_str_new_cstr(mrb, object_getClassName(objc_id(mrb,self)));
	Class objc_class = object_getClass(objc_id(mrb,self));

	if(class_isMetaClass(objc_class)){
		mrb_value ret = mrb_str_new_cstr(mrb, "Class(");
		mrb_str_cat_cstr(mrb, ret, class_getName(objc_class) );
		mrb_str_cat_cstr(mrb, ret, ")");
		return ret;
	}else{
		return objc_id_value(mrb, objc_getClass(class_getName(objc_class)));
	}
}

mrb_value objc_is_kind_of(mrb_state *mrb, mrb_value self){

	mrb_value mrv_objc_class;
	mrb_get_args(mrb, "o", &mrv_objc_class);

	id id_self = objc_id(mrb, self);
	Class class = [objc_id(mrb, mrv_objc_class) class];

	if ([id_self isKindOfClass:class]){
		return mrb_true_value();
	}else{
		return mrb_false_value();
	}

}


mrb_value get_objc_instanceMethods(mrb_state *mrb, mrb_value self){

	Class objc_class = object_getClass(objc_id(mrb, self));
	unsigned int count = 0;
	
	//only for this class
	Method *objc_methods = class_copyMethodList(objc_class, &count);
	mrb_value methods = mrb_ary_new(mrb);

	for (unsigned int i = 0; i < count ; i++){
		SEL selector = method_getName(objc_methods[i]);
		//printf("selname:%s\n",sel_getName(selector));
		const char *sel_name = sel_getName(selector);
		mrb_ary_push(mrb, methods , mrb_symbol_value(mrb_intern_cstr(mrb, sel_name)));
	}
	return methods;

	//To get the class methods of a class, use
	//class_copyMethodList(object_getClass(cls), &count).

}

// id get_id(mrb_value objc_obj){
// 	return (id)mrb_fixnum(mrb_funcall(mrb,objc_obj,0));
// }

// mrb_value kycocoa_const_missing(mrb_state *mrb, mrb_value self){
// 	mrb_value name_obj;
// 	mrb_get_args(mrb, "S", &name_obj);
// 	const char *name = RSTRING_PTR(name_obj);
// 	printf("const missing name = %s\n",name);

// 	id klass = objc_lookUpClass(name);
// 	return mrb_voidp_value(klass);

// 	//TODO : return wrapped(proxy) class object
// }

// mrb_value kycocoa_objc_call(mrb_state *mrb, mrb_value _self){
// 	printf("calling comes to kycocoa_objc_call\n");
// 	mrb_value target_obj;
// 	mrb_value args;
// 	mrb_value selector;
// 	mrb_get_args(mrb,"oSA",&target_obj, &selector, &args);

// 	id target = (id)mrb_voidp(mrb_funcall(mrb, target_obj, "objc_id",0));
// 	SEL selector = sel_registerName(RSTRING_PTR(selector));

// 	Method method = class_getInstanceMethod(Class klass, selector);
// 	const char *encoding = method_getTypeEncoding(method);
// 	swith();
// 	....

// 	mrb_value size_value = mrb_funcall(mrb, args, "size",0);
// 	mrb_int size = mrb_fixnum(size_value);
// 	mrb_value *arg_values = malloc(sizeof(mrb_value) * size);
// 	for (int i = 0; i < size; i++){
// 		arg_values[i] = mrb_funcall(mrb, args, "at",i);
// 	} 

// 	//need to build up types array for arguments.
// 	//How about do parsing of type encoding in Ruby?
// 	//need to know return type

// 	//uups I should use ffi_prep_cif_var from FFI to call objc_msgSend..
// 	//http://www.manpagez.com/man/3/ffi_prep_cif_var/
// 	//http://stackoverflow.com/questions/13404455/using-printf-in-c-when-i-dont-know-how-many-arguments-until-runtime/13405165#13405165
// 	printf("in C, selector name = %s, args.num = %d\n",RSTRING_PTR(selector),size);
// 	return mrb_nil_value();
// }

void
mrb_mruby_kycocoa_gem_init(mrb_state* mrb) {
	struct RClass *kyCocoaModule = mrb_define_module(mrb, "KYCocoa");
	mrb_define_module_function(mrb, kyCocoaModule, "const_missing", kycocoa_const_missing, ARGS_REQ(1));

	// struct RClass *kyCocoaMainClass = mrb_define_class_under(mrb, kyCocoaModule, "KYCocoaMain",mrb->object_class );
	// mrb_define_class_method(mrb, kyCocoaMainClass, "do_objc_msgSend", kycocoa_do_objc_msgSend, ARGS_REQ(2));

	struct RClass *kyCocoaProxy = mrb_define_class_under(mrb, kyCocoaModule, "CocoaProxy", mrb->object_class);
	mrb_define_method(mrb, kyCocoaProxy, "do_objc_msgSend", kycocoa_do_objc_msgSend, ARGS_REQ(2));
	mrb_define_method(mrb, kyCocoaProxy, "objc_instanceMethods", get_objc_instanceMethods, ARGS_OPT(1));
	mrb_define_method(mrb, kyCocoaProxy, "objc_id", kycocoa_objc_id, ARGS_NONE());
	mrb_define_method(mrb, kyCocoaProxy, "objc_id_hex", kycocoa_objc_id_hex, ARGS_NONE());
	mrb_define_method(mrb, kyCocoaProxy, "objc_class", get_objc_class, ARGS_NONE());
	mrb_define_method(mrb, kyCocoaProxy, "objc_isKindOf", objc_is_kind_of, ARGS_REQ(1));
	// mrb_define_const(mrb, kyCocoaModule, "HELLO", mrb_str_new_cstr(mrb, "Hello! KYCocoa"));

	// mrb_define_module_function(mrb, kyCocoaModule,"objc_call", kycocoa_objc_call, ARGS_REQ(3));
	
	// struct RClass *nsStringClass = mrb_define_class_under(mrb, kyCocoaModule, "NSString", mrb->object_class);
}	


void
mrb_mruby_kycocoa_gem_final(mrb_state* mrb) {

}