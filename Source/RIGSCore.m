/* RIGS.m - Ruby Interface to GNUStep

   $Id$

   Copyright (C) 2001 Free Software Foundation, Inc.

   Written by:  Laurent Julliard <laurent@julliard-online.org>
   Date: Aug 2001
   
   This file is part of the GNUstep Ruby  Interface Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.


   History:
     - Original code from Avi Bryant's cupertino test project <avi@beta4.com>
     - Code patiently improved and augmented 
         by Laurent Julliard <laurent.julliard@xrce.xerox.com>

*/

#ifdef _MACOSX_
#include <objc/objc-class.h>
#endif


#ifdef GNUSTEP
#include <objc/encoding.h>
#endif

/* Do not include the whole <Foundation/Foundation.h> to avoid
   conflict with ID definition in ruby.h for MACOSX */
#include <Foundation/NSObject.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSMethodSignature.h>
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>

#include "RIGS.h"
#include "RIGSCore.h"
#include "RIGSWrapObject.h"
#include "RIGSSelectorMapping.h"
#include "RIGSProxySetup.h"
#include "RIGSNSApplication.h"

static char *rigsVersion = RIGS_VERSION;

// Dictionary that maps ObjC class to Ruby class VALUE
static NSMutableDictionary *classValue;

// Dictionary that maps ObjC objects to Ruby object VALUE
static NSMutableDictionary *objectValue;

// Rigs Ruby module
static VALUE rb_mRigs;

/* map to global Ruby variable $STRING_AUTOCONVERT
   If true Ruby Strings are automatically converted
   to NSString and vice versa */
static VALUE stringAutoConvert = Qfalse;

#define IS_STRING_AUTOCONVERT_ON() \
(stringAutoConvert == Qtrue)

/* map to global Ruby variable $SELECTOR_AUTOCONVERT
   If true selectors can be passed to Obj C as Ruby string and
   conversely SEL returned to Ruby are converted to Ruby string
   If false then Ruby must use selector("...") and an NSSelector
   object is returned to Ruby */
static VALUE selectorAutoConvert = Qfalse;

#define IS_SELECTOR_AUTOCONVERT_ON() \
(selectorAutoConvert == Qtrue)




void
rb_objc_release(id objc_object) 
{
    NSDebugLog(@"Call to ObjC release on 0x%lx",objc_object);
    [objectValue removeObjectForKey: objc_object];
    [objc_object release];
}


void
rb_objc_mark(VALUE ruby_object) 
{
    // Doing nothing for the moment
    NSDebugLog(@"Call to ObjC marking on 0x%lx",ruby_object);
}


VALUE
rb_objc_new(int argc, VALUE *argv, VALUE class)
{
    id pool = [[NSAutoreleasePool alloc] init];
    id obj;
    VALUE new_rb_object;
   
    // get the class from the objc_class class variable now
    Class objc_class = (Class) NUM2UINT(rb_iv_get(class, "@objc_class"));
    
    // Normally new method has no arg in objective C. If you want it to have one
    // when called fom Ruby then override the new method from the Ruby side
    // See NSSelector.rb for an example
    obj  = [[objc_class new] retain];
    new_rb_object = Data_Wrap_Struct(class, 0, rb_objc_release, obj);
    
    [objectValue setObject:[NSNumber numberWithUnsignedLong:new_rb_object]
                    forKey:obj ];

    NSDebugLog(@"Creating new object of Class %@ (id = 0x%lx, VALUE = 0x%lx)",
               NSStringFromClass([objc_class class]), obj, new_rb_object);

    [pool release];
    return new_rb_object;
}

BOOL
rb_objc_convert_to_objc(VALUE rb_val,void *data, const char *type)
{
  BOOL ret = YES;
  Class objcClass;
  NSString *msg;
  VALUE rb_class_val;

  
  // If Ruby gave the NIL value then bypass all the rest
  if(NIL_P(rb_val)) {
    *(id*)data = (id) nil;
    return YES;
  } 
  
  // All other cases
  switch (*type) {
      
  case _C_ID:
  case _C_CLASS:

    switch (TYPE(rb_val))
      {
      case T_DATA:
        Data_Get_Struct(rb_val,id,* (id*)data);
          
        /* Automatic conversion from string -- see below _C_SEL case
           if ([ret class] == [NSSelector class]) {
           ret = [ret getSEL];
           NSDebugLog(@"Extracting ObjC SEL (0x%lx) from NSSelector object", ret);
           } */
          
        break;
          
          
      case T_STRING:
        /* Ruby sends a string to a ObjC method waiting for an id
                  so convert it to NSString automatically */
        *(NSString**)data = [NSString stringWithCString: STR2CSTR(rb_val)];
        break;
          
      case T_OBJECT:
      case T_CLASS:
        /* Ruby sends a Ruby class or a ruby object. Automatically register
                 an ObjC proxy class. It is very likely that we'll need it in the future
                 (e.g. typical for setDelegate method call) */
        rb_class_val = (TYPE(rb_val) == T_CLASS ? rb_val : CLASS_OF(rb_val));
        NSDebugLog(@"Converting object of Ruby class: %s", rb_class2name(rb_class_val));
        objcClass = _RIGS_register_ruby_class(rb_class_val);
        *(id*)data = (id)[objcClass objectWithRubyObject: rb_val];
        NSDebugLog(@"Wrapping Ruby Object of type: 0x%02x (ObjC object at 0x%lx)",TYPE(rb_val), *(id*)data);
        break;
          
      case T_ARRAY:
      case T_HASH:
        /* For hashes and array do not create ObjC proxy for the moment 
                  FIXME?? Should probably be handled like T_OBJECT and T_CLASS */
        *(id*)data = (id) [RIGSWrapObject objectWithRubyObject: rb_val];
        NSDebugLog(@"Wrapping Ruby Object of type: 0x%02x (ObjC object at 0x%lx)",TYPE(rb_val), *(id*)data);
        break;

      case T_FIXNUM:
        // automatic morphing into a NSNumber Int
        *(NSNumber**)data = [NSNumber numberWithInt: FIX2INT(rb_val)];
        break;
        
      case T_BIGNUM:
          // Possible overflow because bignum can be very big!!!
          // FIXME: not sure how to check the overflow
          *(NSNumber**)data = [NSNumber numberWithInt: FIX2INT(rb_val)];
        break;

      case T_FLOAT:
        // Map it to double in any case to be sure there isn't any overflow
        *(NSNumber**)data = [NSNumber numberWithDouble: NUM2DBL(rb_val)];
        break;

      case T_FALSE:
        *(BOOL*)data = NO;
        break;

      case T_TRUE:
        *(BOOL*)data = YES;
        break;

      default:
        ret = NO;
        break;
                
      }
    break;

  case _C_SEL:
    if (TYPE(rb_val) == T_STRING) {
            
      *(SEL*)data = NSSelectorFromString([NSString stringWithCString: STR2CSTR(rb_val)]);
            
    } else if (TYPE(rb_val) == T_DATA) {

        // This is in case the selector is passed as an instance of NSSelector
        // which is a class the we have created
        id object;
        Data_Get_Struct(rb_val,id,object);
        if ([object isKindOfClass: [NSSelector class]]) {
            *(SEL*)data = [object getSEL];
        } else {
            ret = NO;
        }

    } else {
        ret = NO;
    }
    break;
 

  case _C_CHR:
    if ((TYPE(rb_val) == T_FIXNUM) || (TYPE(rb_val) == T_STRING)) 
      *(char*)data = (char) NUM2CHR(rb_val);
    else
      ret = NO;
    break;

  case _C_UCHR:
    if ( ((TYPE(rb_val) == T_FIXNUM) && FIX2INT(rb_val)>=0) ||
         (TYPE(rb_val) == T_STRING)) 
      *(char*)data = (char) NUM2CHR(rb_val);
    else if (TYPE(rb_val) == T_TRUE)
      *(unsigned char*)data = YES;
    else if (TYPE(rb_val) == T_FALSE)
      *(unsigned char*)data = NO;
    else
      ret = NO;
    break;

  case _C_SHT:
    if (TYPE(rb_val) == T_FIXNUM) 
      if (FIX2INT(rb_val) <= SHRT_MAX || FIX2INT(rb_val) >= SHRT_MIN) 
        *(short*)data = (short) FIX2INT(rb_val);
      else {
        NSLog(@"*** Short overflow %d",FIX2INT(rb_val));
        ret = NO;
      }        
    else
      ret = NO;
    break;

  case _C_USHT:
    if (TYPE(rb_val) == T_FIXNUM) 
      if (FIX2INT(rb_val) <= USHRT_MAX || FIX2INT(rb_val) >=0)
        *(unsigned short*)data = (unsigned short) FIX2INT(rb_val);
      else {
        NSLog(@"*** Unsigned Short overflow %d",FIX2INT(rb_val));
        ret = NO;
      } else {
          ret = NO;
      }
    break;

  case _C_INT:
    if (TYPE(rb_val) == T_FIXNUM || TYPE(rb_val) == T_BIGNUM )
      *(int*)data = (int) NUM2INT(rb_val);
    else
      ret = NO;	  
    break;

  case _C_UINT:
    if (TYPE(rb_val) == T_FIXNUM || TYPE(rb_val) == T_BIGNUM)
      *(unsigned int*)data = (unsigned int) NUM2INT(rb_val);
    else
      ret = NO;
    break;

  case _C_LNG:
    if (TYPE(rb_val) == T_FIXNUM || TYPE(rb_val) == T_BIGNUM )
      *(long*)data = (long) NUM2INT(rb_val);
    else
      ret = NO;	  	
    break;

  case _C_ULNG:
    if (TYPE(rb_val) == T_FIXNUM || TYPE(rb_val) == T_BIGNUM )
      *(unsigned long*)data = (unsigned long) NUM2INT(rb_val);
    else
      ret = NO;	  	
    break;


  case _C_FLT:
    if ( (TYPE(rb_val) == T_FLOAT) || 
         (TYPE(rb_val) == T_FIXNUM) ||
         (TYPE(rb_val) == T_BIGNUM) ) {

        // FIXME: possible overflow but don't know (yet) how to check it ??
        *(float*)data = (float) NUM2DBL(rb_val);
        NSDebugLog(@"Converting ruby value to float : %f", *(float*)data);
    }
    else
      ret = NO;	  	
    break;
	   

  case _C_DBL:
    if ( (TYPE(rb_val) == T_FLOAT) || 
         (TYPE(rb_val) == T_FIXNUM) ||
         (TYPE(rb_val) == T_BIGNUM) ) {
        
        // FIXME: possible overflow but don't know (yet) how to check it ??
        *(double*)data = (double) NUM2DBL(rb_val);
        NSDebugLog(@"Converting ruby value to double : %lf", *(double*)data);
    }
    else
      ret = NO;	  	
    break;

  case _C_CHARPTR:
    // Inspired from the Guile interface
    if (TYPE(rb_val) == T_STRING) {
            
      NSMutableData	*d;
      char		*s;
      int		l;
            
      s = STR2CSTR(rb_val);
      l = strlen(s)+1;
      d = [NSMutableData dataWithBytesNoCopy: s length: l];
      *(char**)data = (char*)[d mutableBytes];
            
    } else if (TYPE(rb_val) == T_DATA) {
      // I guess this is the right thing to do. Pass the
      // embedded ObjC as a blob
      Data_Get_Struct(rb_val,char* ,* (char**)data);
    } else {
      ret = NO;
    }
    break;
   

  case _C_PTR:
    // Inspired from the Guile interface. Same as char_ptr above
    if (TYPE(rb_val) == T_STRING) {
            
      NSMutableData	*d;
      char		*s;
      int		l;
            
      s = STR2CSTR(rb_val);
      l = strlen(s);
      d = [NSMutableData dataWithBytesNoCopy: s length: l];
      *(void**)data = (void*)[d mutableBytes];
            
    } else if (TYPE(rb_val) == T_DATA) {
      // I guess this is the right thing to do. Pass the
      // embedded ObjC as a blob
      Data_Get_Struct(rb_val,void* ,*(void**)data);
    } else {
      ret = NO;
    }
    break;


  case _C_STRUCT_B:
    ret = NO;
    break;


  default:
    ret =NO;
    break; 
  }
    
  
  if (ret == NO) {
    /* raise exception - Don't know how to handle this type of argument */
    msg = [NSString stringWithFormat: @"Don't know how to convert Ruby type 0x%02xin ObjC type '%c'", TYPE(rb_val), *type];
    NSDebugLog(msg);
    rb_raise(rb_eTypeError, [msg cString]);
  }

  return ret;
  
}


BOOL
rb_objc_convert_to_rb(void *data, const char *type, VALUE *rb_val_ptr)
{
    BOOL ret = YES;
    VALUE rb_class;
    double dbl_value;
    NSSelector *selObj;

    NSDebugLog(@"Converting ObjC value (location 0x%lx, type '%c') to Ruby",
               *(id*)data, type[0]);
    
    switch (type[0])
        {
        case _C_ID: 
          {
            id val = *(id*)data;

            // Check if the ObjC object is already wrapped into a Ruby object
            // If so do not create a new object. Return the existing one
            if ( (*rb_val_ptr = (VALUE)[[objectValue objectForKey:val] unsignedLongValue] ) )  
            {
                NSDebugLog(@"ObJC object already wrapped in an existing Ruby value (0x%lx)",*rb_val_ptr);
                return YES;
            }
                 

            if (val == nil) {

              *rb_val_ptr = Qnil;
              
            } else if ( [val class] == [RIGSWrapObject class] ) {
              
              // This a native ruby object wrapped into an Objective C 
              // nutshell. Returns what's in the nutshell
              *rb_val_ptr = [val getRubyObject];
              
            } else if ( [val isKindOfClass: [NSString class]] &&
                        ( IS_STRING_AUTOCONVERT_ON() ) ) {
              
              // FIXME: Not sure what to do with memory management here ??
              *rb_val_ptr = rb_str_new2([val cString]);
              
            } else {
              
              // Retain the value otherwise GNUStep releases it and Ruby crashes
              // It's Ruby's garbage collector job to indirectly release the ObjC 
              // object by calling rb_objc_release() */
              [val retain];
              NSDebugLog(@"Class of arg transmitted to Ruby = %@",NSStringFromClass([val class]));             
              rb_class = [ [classValue objectForKey:[val class]] unsignedLongValue];
              
              // if the class of the returned object is unknown to Ruby
              // then register the new class with Ruby first
              if (rb_class == (VALUE)nil) {
                rb_class = rb_objc_register_class_from_objc([val class]);
              }
              *rb_val_ptr = Data_Wrap_Struct(rb_class,0,rb_objc_release,val);
            }
          }
          break;

        case _C_CHARPTR: 
          {
            // Convert char * to ruby String
            char *val = *(char **)data;
            if (val)
              *rb_val_ptr = rb_str_new2(val);
            else 
              *rb_val_ptr = Qnil;
          }
          break;

        case _C_PTR:
          {
            // FIXME??: Don't know what how to convert a void * to Ruby 
            *rb_val_ptr = Qnil;
            NSLog(@"Don't know how to convert void * (_C_PTR) to ruby (0x%lx)",*(void**)data);
            ret = NO;
          }
          break;

        case _C_CHR:
          *rb_val_ptr = CHR2FIX(*(unsigned char *)data);
            break;

        case _C_UCHR:
            // Assume that if YES or NO then it's a BOOLean
            if ( *(unsigned char *)data == YES) 
                *rb_val_ptr = Qtrue;
            else if ( *(unsigned char *)data == NO)
                *rb_val_ptr = Qfalse;
            else
                *rb_val_ptr = CHR2FIX(*(unsigned char *)data);
            break;

        case _C_SHT:
            *rb_val_ptr = INT2FIX((int) (*(short *) data));
            break;

        case _C_USHT:
            *rb_val_ptr = INT2FIX((int) (*(unsigned short *) data));
            break;

        case _C_INT:
            *rb_val_ptr = INT2FIX(*(int *)data);
            break;

        case _C_UINT:
            *rb_val_ptr = INT2FIX(*(unsigned int*)data);
            break;

        case _C_LNG:
            *rb_val_ptr = INT2NUM(*(long*)data);
            break;

        case _C_ULNG:
            *rb_val_ptr = INT2FIX(*(unsigned long*)data);
            break;

        case _C_FLT:
          {
            // FIXME
            // This one doesn't crash but returns a bad floating point
            // value to Ruby. val doesn not contain the expected float
            // value. why???
            NSDebugLog(@"ObjC val for float = %f", *(float*)data);
            
            dbl_value = (double) (*(float*)data);
            NSDebugLog(@"Double ObjC value returned = %lf",dbl_value);
            *rb_val_ptr = rb_float_new(dbl_value);
          }
          break;

        case _C_DBL:
            NSDebugLog(@"Double float Value returned = %lf",*(double*)data);
             *rb_val_ptr = rb_float_new(*(double*)data);
            break;


        case _C_CLASS:
          {
            Class val = *(Class*)data;
            
            NSDebugLog(@"ObjC Class = 0x%lx", val);
            rb_class = [ [classValue objectForKey:val] unsignedLongValue];
            // if the Class is unknown to Ruby then register it 
            // in Ruby in return the corresponding Ruby class VALUE
            if (rb_class == (VALUE)nil) {
                rb_class = rb_objc_register_class_from_objc(val);
            }
            *rb_val_ptr = rb_class;
          }
          break;
          
        case _C_SEL: 
          {
            SEL val = *(SEL*)data;
            
            NSDebugLog(@"ObjC Selector = 0x%lx", val);
            // ObjC selectors can either be returned as Ruby String
            // or as instance of class NSSelector
            if (IS_SELECTOR_AUTOCONVERT_ON()) {
              
              *rb_val_ptr = rb_str_new2([NSStringFromSelector(val) cString]);
              
            } else {
              
              // Before instantiating NSSelector make sure it is known to
              // Ruby
              rb_class = [ [classValue objectForKey:[NSSelector class]] unsignedLongValue];
              if (rb_class == (VALUE)nil) {
                rb_class = rb_objc_register_class_from_objc([NSSelector class]);
              }
              selObj = [[NSSelector selectorWithSEL: (SEL)val] retain];
              *rb_val_ptr = Data_Wrap_Struct(rb_class,0,rb_objc_release,selObj);
            }
          }
          break;

        default:
            NSLog(@"Don't know how to convert ObjC type '%c' to Ruby VALUE",type[0]);
            *rb_val_ptr = Qnil;
            ret = NO;
            
            break;
        }
      
    NSDebugLog(@"End of ObjC conversion to Ruby");
    
    return ret;

}


VALUE
rb_objc_send(char *method, int argc, VALUE *argv, VALUE self)
{
    SEL sel;
    id pool = [[NSAutoreleasePool alloc] init];

  NSDebugLog(@"<<<< Invoking method %s with %d argument(s) on Ruby VALUE 0x%lx (Objc id 0x%lx)",method, argc, self);
  sel = SelectorFromRubyName(method, argc > 0);
  [pool release];

  return rb_objc_send_with_selector(sel, argc, argv, self);
}

VALUE rb_objc_send_with_selector(SEL sel, int argc, VALUE *argv, VALUE self)
{
    id pool = [NSAutoreleasePool new];
    id rcv;
    NSInvocation *invocation;
    NSMethodSignature	*signature;
    const char *type;
    VALUE rb_retval = Qnil;
    int i;
    int nbArgs;
    void *data;
    BOOL okydoky;
        
        
    /* determine the receiver type - Class or instance */
    switch (TYPE(self)) {

    case T_DATA:
        NSDebugLog(@"Self Ruby value is 0x%lx (ObjC is at 0x%lx)",self,DATA_PTR(self));
        
        Data_Get_Struct(self,id,rcv);
        
        NSDebugLog(@"Self is an object of Class %@ (description is '%@')",NSStringFromClass([rcv class]),rcv);
      break;

    case T_CLASS:
        rcv = (id) NUM2UINT(rb_iv_get(self, "@objc_class"));
        NSDebugLog(@"Self is of class: %@", NSStringFromClass(rcv));
      break;

    default:
      /* raise exception */
      NSDebugLog(@"Don't know how to handle self Ruby object of type 0x%02x",TYPE(self));
      rb_raise(rb_eTypeError, "not valid self value");
      return Qnil;
      break;
      
    }
  
      
    // Find the method signature 
    // FIXME: do not know what happens here if several method have the same
    // selector and different return types (see gg_id.m / gstep_send_fn ??)
    signature = [rcv methodSignatureForSelector: sel];
    if (signature == nil) {
        NSLog(@"Did not find signature for selector '%@' ..", 
              NSStringFromSelector(sel));
        return Qnil;
    }
  

    // Check that we have the right number of arguments
    nbArgs = [signature numberOfArguments];
    if ( nbArgs != argc+2) {
        rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)",argc, nbArgs-2);
        return Qnil;
    }
    
    NSDebugLog(@"Number of arguments = %d", nbArgs-2);

    // Create an Objective C invocation based on the  signature
    // and convert arguments from Ruby VALUE to ObjC types
    invocation = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget: rcv];
    [invocation setSelector: sel];
	
    for(i=2; i < nbArgs; i++) {

#if     defined(GNUSTEP_BASE_VERSION)
        type = [signature getArgumentTypeAtIndex: i];
#elif   defined(LIB_FOUNDATION_LIBRARY)
        type = ([signature argumentInfoAtIndex: i]).type;
#else
#include "DON'T KNOW HOW TO GET METHOD SIGNATURE INFO"
#endif
        data = alloca(objc_sizeof_type(type));
                        
        okydoky = rb_objc_convert_to_objc(argv[i-2], data, type);
        [invocation setArgument: data atIndex: i];
    }
 
    // Really invoke the Obj C method now
    [invocation invoke];

    // Examine the return value now and pass it by to Ruby
    // after conversion
    if([signature methodReturnLength]) {

        type = [signature methodReturnType];
            
        NSDebugLog(@"Return Length = %d", [[invocation methodSignature] methodReturnLength]);
        NSDebugLog(@"Return Type = %s", type);
        
        data = alloca([signature methodReturnLength]);
        [invocation getReturnValue: data];

        // Won't work if return length > sizeof(int)  but we do not care
        // (e.g. double on 32 bits architecture)
        NSDebugLog(@"ObjC return value = 0x%lx",data);

        okydoky = rb_objc_convert_to_rb(data, type, &rb_retval);

    } else {
        // This is a method with no return value (void). Must return something
        // in any case in ruby. So return Qnil.
        NSDebugLog(@"No ObjC return value (void) - returning Qnil",data);
        rb_retval = Qnil;
    }
        
        
    NSDebugLog(@">>>>> VALUE returned to Ruby 0x%lx",rb_retval);
        
    [pool release];	
    return rb_retval;
}

VALUE 
rb_objc_handler(int argc, VALUE *argv, VALUE self)
{    
	return rb_objc_send(rb_id2name(rb_frame_last_func()), argc, argv, self);
}

VALUE 
rb_objc_to_s_handler(VALUE self)
{
    id pool = [NSAutoreleasePool new];
    id rcv;
    VALUE rb_desc;

    // Invoke ObjC description method and always return a Ruby string
    Data_Get_Struct(self,id,rcv);
    rb_desc = rb_str_new2([[rcv description] cString]);
 
    [pool release];
    return rb_desc;

}

VALUE
rb_objc_invoke(int argc, VALUE *argv, VALUE self)
{
	char *method = rb_id2name(SYM2ID(argv[0]));
 
	return rb_objc_send(method, argc-1, argv+1, self);
}

NSArray* 
class_method_selectors_for_class(Class class, BOOL use_super)
{    
  Class meta_class =  class_get_meta_class(class);
  return(method_selectors_for_class(meta_class, use_super));
}

NSArray* 
instance_method_selectors_for_class(Class class, BOOL use_super)
{
  return(method_selectors_for_class(class, use_super));
}

/*
This is to mimic a  MACOSX function and have a single
method_selectors_for_class  function for MACOSX and GNUstep
(see below)
*/
#ifdef GNUSTEP
static MethodList_t class_nextMethodList( Class class, void ** iterator_ptr) 
{
  MethodList_t mlist;
  
  if (*iterator_ptr) {
    mlist = ((MethodList_t) (*iterator_ptr) )->method_next;
  } else {
    mlist = class->methods;
  }

  *iterator_ptr = (void *)mlist;
  return mlist;
    
}

#endif

NSArray* 
method_selectors_for_class(Class class, BOOL use_super)
{
  MethodList_t mlist;     
  NSMutableSet *methodSet = [NSMutableSet new];
  int i;
  void *iterator = NULL;

  while(class) {

    while( (mlist = class_nextMethodList(class, &iterator)) != NULL) {
      
          for(i = 0; i < mlist->method_count; i++) {
              SEL sel = mlist->method_list[i].method_name;
              [methodSet addObject: NSStringFromSelector(sel)];
              //NSLog(@"method name %@",NSStringFromSelector(sel));
          }
    }
                
    if(use_super)
      class = class->super_class;
    else
      class = NULL;
  }

  return [methodSet allObjects];
}

int rb_objc_register_instance_methods(Class objc_class, VALUE ruby_class)
{
    NSArray *allMthSels;
    NSEnumerator *mthEnum;
    NSString *mthSel;
    NSString *mthRubyName;
    int imth_cnt = 0;

    //Store the ObjcC Class id in the @@objc_class Ruby Class Variable
    rb_iv_set(ruby_class, "@objc_class", INT2NUM((int)objc_class));
    
    /* Define all Ruby Instance methods for this Class */
    allMthSels = method_selectors_for_class(objc_class, NO);
    mthEnum = [allMthSels objectEnumerator];
    
    while ( (mthSel = [mthEnum nextObject]) ) {
       
        mthRubyName = RubyNameFromSelectorString(mthSel);
        //NSDebugLog(@"Registering Objc method %@ under Ruby name %@)", mthSel,mthRubyName);

        rb_define_method(ruby_class, [mthRubyName cString], rb_objc_handler, -1);
        imth_cnt++;
    }

    // map ObjC object description method to Ruby to_s
    // Ideally it should be a new method calling description and returning
    //rb_define_alias(ruby_class, "to_s", "description");
    rb_define_method(ruby_class, "to_s", rb_objc_to_s_handler,0);
    return imth_cnt;
    
}

int rb_objc_register_class_methods(Class objc_class, VALUE ruby_class)
{
    NSArray *allMthSels;
    NSEnumerator *mthEnum;
    NSString *mthSel;
    NSString *mthRubyName;
    Class objc_meta_class = class_get_meta_class(objc_class);
    
    int cmth_cnt = 0;

    
    /* Define all Ruby Class (singleton) methods for this Class */
    allMthSels = method_selectors_for_class(objc_meta_class, NO);
    mthEnum = [allMthSels objectEnumerator];
    
    while ( (mthSel = [mthEnum nextObject]) ) {
       
        mthRubyName = RubyNameFromSelectorString(mthSel);
        //NSDebugLog(@"Registering Objc class method %@ under Ruby name %@)", mthSel,mthRubyName);

        rb_define_singleton_method(ruby_class, [mthRubyName cString], rb_objc_handler, -1);
        cmth_cnt++;
     }

    // Redefine the new method to point to our special rb_objc_new function
    rb_undef_method(CLASS_OF(ruby_class),"new");
    rb_define_singleton_method(ruby_class, "new", rb_objc_new, -1);

    return cmth_cnt;
}


VALUE
rb_objc_register_class_from_objc (Class objc_class)
{

    id pool = [[NSAutoreleasePool alloc] init];
    const char *cname = [NSStringFromClass(objc_class) cString];

    Class objc_super_class = [objc_class superclass];
    VALUE ruby_class;
    VALUE ruby_super_class = Qnil;
    NSNumber *ruby_class_value;
    int imth_cnt;
    int cmth_cnt;

    NSDebugLog(@"Request to register ObjC Class %s (ObjC id = 0x%lx)",cname,objc_class);

    // If this class has already been registered then return existing
    // Ruby class VALUE
    ruby_class_value = [classValue objectForKey:objc_class];
    if (ruby_class_value != nil) {
       NSDebugLog(@"Class %s already registered (VALUE 0x%lx)",
             cname,[ruby_class_value unsignedLongValue]);
       return [ruby_class_value unsignedLongValue];
    }

    // If it is not the mother of all classes then create the
    // Ruby super class first
    if ((objc_class == [NSObject class]) || (objc_super_class == nil)) 
        ruby_super_class = rb_cObject;
    else
        ruby_super_class = rb_objc_register_class_from_objc(objc_super_class);

    ruby_class = rb_define_class_under(rb_mRigs, cname, ruby_super_class);

    cmth_cnt = rb_objc_register_class_methods(objc_class, ruby_class);
    imth_cnt = rb_objc_register_instance_methods(objc_class, ruby_class);

    NSDebugLog(@"%d instance and %d class methods defined for class %s",imth_cnt,cmth_cnt,cname);

    // Remember that this class is now defined in Ruby
    ruby_class_value = [NSNumber numberWithUnsignedLong:ruby_class];  
    [classValue setObject:ruby_class_value forKey:objc_class];
    NSDebugLog(@"VALUE for new Ruby Class %s = 0x%lx",cname,ruby_class);

    // Execute Post registration code if it exists
    if ( [objc_class respondsToSelector: @selector(finishRegistrationOfRubyClass:)] ) {
      [objc_class finishRegistrationOfRubyClass: ruby_class];
    } else {
      NSDebugLog(@"Class %@ doesn't respond to finish registration method",NSStringFromClass(objc_class));
    } 

    // also make sure to load the corresponding ruby file and execute
    // any additional Ruby code for this class
    // it is like: Rigs.import(cname)
    // FIXME: It goes into recursive call with the Ruby NSxxx.rb code and leads
    // to top level constant defined twice (warning). Need to fix that...
    //NSLog(@"Calling RIGS.importC(%s) from Objc", cname);
    
    rb_funcall(rb_mRigs, rb_intern("import"), 1,rb_str_new2(cname));
    
    // Define a top level Ruby constant  with the same name as the class name
    // No don't do that! Force user to use Rigs#import on the Ruby side to
    // load any additional Ruby code if there is some
    //rb_define_global_const(cname, ruby_class);

    [pool release];
    return ruby_class;
}

VALUE
rb_objc_register_class_from_ruby(VALUE self, VALUE name)
{
    id pool = [[NSAutoreleasePool alloc] init];		
    char *cname = STR2CSTR(name);
    VALUE ruby_class = Qnil;

    Class objc_class = NSClassFromString([NSString stringWithCString: cname]);
    
    if(objc_class)
        ruby_class = rb_objc_register_class_from_objc(objc_class);

    [pool release];
    return ruby_class;
}

VALUE
rb_objc_get_ruby_value_from_string(char * classname)
{
    char *evalstg;
    VALUE rbvalue;
    
    // Determine the VALUE of a Ruby Class based on its name
    // Not sure this is the official way of doing it... (FIXME?)
    evalstg = malloc(strlen(classname)+5);
    strcpy(evalstg,classname);
    strcat(evalstg,".id");
    // FIXME??: test if equivalent to ID2SYM(rb_eval_string(evalstg))
    rbvalue = rb_eval_string(evalstg) & ~FIXNUM_FLAG;
    free(evalstg);

    return rbvalue;
}


void
rb_objc_raise_exception(NSException *exception)
{
    VALUE ruby_rterror_class, rb_exception;
    
    NSDebugLog(@"Uncaught Objective C Exception raised !");
    NSDebugLog(@"Name:%@  / Reason:%@  /  UserInfo: ?",
               [exception name],[exception reason]);

    // Declare a new Ruby Exception Class on the fly under the RuntimeError
    // exception class
    // Rk: the 1st line below  is the only way I have found to get access to
    // the VALUE of the RuntimeError class. Pretty ugly.... but it works.
    //    ruby_rterror_class = rb_eval_string("RuntimeError.id") & ~FIXNUM_FLAG;
    ruby_rterror_class = rb_objc_get_ruby_value_from_string("RuntimeError");
    rb_exception = rb_define_class([[exception name] cString], ruby_rterror_class);
    rb_raise(rb_exception, [[exception reason] cString]);
    
}




/* Called when require 'librigs' is executed in Ruby */
void
Init_librigs()
{

    // Catch all GNUstep raised exceptions and direct them to Ruby
    NSSetUncaughtExceptionHandler(rb_objc_raise_exception);

    // Initialize Object and Class hash tables
    classValue = [NSMutableDictionary new];
    objectValue = [NSMutableDictionary new];
    
    // Create 2 ruby class methods under the ObjC Ruby module
    // - Rigs.class("className") : registers ObjC class with Ruby
    // - Rigs.register(class): register Ruby class with Objective C

    rb_mRigs = rb_define_module("Rigs");
    rb_define_singleton_method(rb_mRigs, "class", rb_objc_register_class_from_ruby, 1);
    rb_define_singleton_method(rb_mRigs, "register", _RIGS_register_ruby_class_from_ruby, 1);
 
    /* Some variable visible from Ruby
           - STRING_AUTOCONVERT: determine whether Ruby String are
              systematically converted to NSString and vice-versa.
           - SELECTOR_AUTOCONVERT: determine whether Ruby Strings are
              systematically converted to Selector when ObjC expects a selector
             and vice-versa when a selector is returned to ruby    */
    rb_global_variable(&stringAutoConvert);
    rb_define_variable("$STRING_AUTOCONVERT", &stringAutoConvert);
    rb_global_variable(&selectorAutoConvert);
    rb_define_variable("$SELECTOR_AUTOCONVERT", &selectorAutoConvert);

    // Define Rigs::VERSION in Ruby
    rb_define_const(rb_mRigs, "VERSION", rb_str_new2(rigsVersion));

    // Define the NSNotFound enum constant that is used all over the place
    // as a return value by Objective C methods
    rb_define_global_const("NSNotFound", INT2FIX((int)NSNotFound));

}

/* In case the library is compile with debug=yes */
void
Init_librigs_d()
{
    Init_librigs();
}
