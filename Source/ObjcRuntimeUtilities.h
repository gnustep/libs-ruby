/* ObjcRuntimeUtilities.h - Utilities to add classes and methods 
   in the Objective-C runtime, at runtime.

   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by:  Nicola Pero <nicola@brainstorm.co.uk>
   Date: June 2000
   
   This file is part of the GNUstep Java Interface Library.

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

#ifndef __ObjcRuntimeUtilities_h_GNUSTEP_RUBY_INCLUDE
#define __ObjcRuntimeUtilities_h_GNUSTEP_RUBY_INCLUDE

#include <objc/objc-api.h>
#include <objc/encoding.h>
#include <Foundation/Foundation.h>

/* 
 * This code is by no means tidied to Java.  

 * It provides facilities to programmatically add classes and methods
 * to the objc runtime, while the runtime is already running.

 * It could be reused for building interfaces to other languages.

 * At present this code only works with the GNU Objective-C Runtime, 
 * because we need to access the runtime internal structures to add 
 * classes and methods. 
 */

/*

  Creating a new class

  */

/*
 * ObjcUtilities_new_class:
 *
 * Create a new Objective-C class called name, inheriting from
 * superClass.  

 * If ivarNumber is zero, the new class has not any more instance
 * variables than the class it inherits from.

 * Otherwise, appropriate optional arguments should be provided; they
 * should come in couples; the first one is the ivar name, the second
 * one the ivar type.  For example: 
 * ObjcUtilities_new_class ("MyNiceClass", "NSObject", 2, 
 *                          "aJavaObject", @encode (jobject), 
 *                          "tag", @encode (int)); 
 * creates a class as it would be created by
 *
 * @interface MyNiceClass : NSObject 
 * {
 *   jobject aJavaObject;
 *   int     tag;
 * }
 * @end

 * Return NO upon failure (because the class already exists or the
 * superclass does not exist), and YES upon success.
 
 */

BOOL ObjcUtilities_new_class (const char *name, const char *superclassName, 
			      int ivarNumber, ...);

/*

  Adding new methods to a class

  Quick HOWTO: 
  A. alloc a MethodList using ObjcUtilities_alloc_method_list.
  B. insert the methods you want to register in the MethodList using 
     ObjcUtilities_insert_method_in_list.
     To get the objective-C runtime type for a method, you may want to use 
     ObjcUtilities_build_runtime_Objc_signature
  C. register your method list with the objective-C runtime using 
     ObjcUtilities_register_method_list.
  */

/*
 * ObjcUtilities_alloc_method_list:
 *
 * Allocate a MethodList capable of containing `count' methods. 
 * A pointer to the allocated list is returned. 
 *
 */

MethodList *ObjcUtilities_alloc_method_list (int count);

/*
 * ObjcUtilities_insert_method_in_list:
 *
 * Insert a method definition in a MethodList.  `ml' is a pointer to
 * the MethodList.  `index' is the index of the method to add.  `name'
 * is the name of the method; `types' is the objective-C run-time
 * signature of the method (see below for a facility to create this
 * automatically), `imp' is the IMP (ie, the actual implementation of
 * the method).  `imp' must be a pointer to a function taking the
 * correct arguments and returning the correct type; cast it to an IMP 
 * then before calling this function.
 */

void ObjcUtilities_insert_method_in_list (MethodList *ml, 
					  int index, const char *name, 
					  const char *types, IMP imp);

/*
 * ObjcUtilities_build_runtime_Objc_signature:
 *
 * This method creates a runtime objc signature which can be used 
 * to describe type for a selector *on this machine* (you need this 
 * signature for example to insert a method description in a method list,
 * using the ObjcUtilities_insert_method_in_list function above).
 *
 * It takes as argument a 'naive' objc signature, in the form of 
 * a string obtained by concatenating the following strings: 
 *
 * @encode(return_type)
 *
 * @encode(Class) if it's a class method, or @encode(id) if it's an
 * instance method (corresponding to the first hidden argument, self)
 *
 * @encode(SEL) (corresponding to the second hidden argument, the selector)
 *
 * @encode(arg1) @encode(arg2) ... if there are any real arguments. 
 * 
 * An example is: 
 * "i@:@" for an instance method returning int and taking an object arg. 
 * (NB: "i" = @encode(int), "@" = @encode(id), ":" = @encode(SEL)).
 *
 * On my machine, ObjcUtilities_build_runtime_Objc_signature ("i@:@")
 * returns "i12@0:4@8", which I can then use as selector type when 
 * creating entries in MethodList.
 *
 */

const char *ObjcUtilities_build_runtime_Objc_signature (const char *);

/*
 * ObjcUtilities_register_method_list:
 *
 * Add the list `ml' of methods to an existing Class `class'.
 * They are registered as instance methods. 
 * To add class methods, you simply need to pass the meta class 
 * [(Class)class->class_pointer] instead of the class.
 *
 * *Never* release or modify a method list after registering it with
 * *the objective-C runtime.  
 */

void ObjcUtilities_register_method_list (Class class, MethodList *ml);

#endif /* __ObjcRuntimeUtilitis_h_GNUSTEP_RUBY_INCLUDE */
