/* RIGSCore.h - Ruby Interface to GNUStep - main module

   $Id$

   Copyright (C) 2001 Free Software Foundation, Inc.
   
   Written by:  Laurent Julliard <laurent@julliard-online.org>
   Date: July 2001
   
   This file is part of the GNUstep RubyInterface Library.

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
   */ 

#ifndef __RIGSCore_h_GNUSTEP_RUBY_INCLUDE
#define __RIGSCore_h_GNUSTEP_RUBY_INCLUDE

#include <Foundation/NSException.h>

// After inclusion of ruby.h undefine the "_" macro because 
// it is also defined in Foundation/NSBundle.h
#include "ruby.h"
#undef _

void  rb_objc_release(id objc_object);
void  rb_objc_mark(VALUE ruby_object);
VALUE rb_objc_new(int argc, VALUE *argv, VALUE class);

BOOL rb_objc_convert_to_objc(VALUE rb_val, void *data, const char *type);
BOOL rb_objc_convert_to_rb(void *data, const char *type, VALUE *rb_val);

VALUE rb_objc_send(char *method, int argc, VALUE *argv, VALUE self);
VALUE rb_objc_send_with_selector(SEL sel, int argc, VALUE *argv, VALUE self);
VALUE rb_objc_handler(int argc, VALUE *argv, VALUE self);
VALUE rb_objc_invoke(int argc, VALUE *argv, VALUE self);

NSArray* class_method_selectors_for_class(Class class, BOOL use_super);
NSArray* instance_method_selectors_for_class(Class class, BOOL use_super);
NSArray* method_selectors_for_class(Class class, BOOL use_super);

int rb_objc_register_instance_methods(Class objc_class, VALUE ruby_class);
int rb_objc_register_class_methods(Class objc_class, VALUE ruby_class);
VALUE rb_objc_register_class_from_objc (Class objc_class);
VALUE rb_objc_register_class_from_ruby(VALUE self, VALUE name);
VALUE rb_objc_get_ruby_value_from_string(char * classname);

void rb_objc_raise_exception(NSException *exception);
void Init_librigs();
void Init_librigs_d();

#endif
