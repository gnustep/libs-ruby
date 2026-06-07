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

#import <Foundation/Foundation.h>
#import <GNUstepBase/GSObjCRuntime.h>

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

  To get the Objective-C runtime type for a method, you may want to use 
  ObjcUtilities_build_runtime_Objc_signature before adding the method with
  ObjcUtilities_add_method.
  */

/*
 * ObjcUtilities_add_method:
 *
 * Add a method definition to a class.  `class' is the class to modify,
 * `name' is the selector name, `types' is the Objective-C run-time
 * signature of the method, and `imp' is the implementation.
 *
 */

BOOL ObjcUtilities_add_method (Class class, const char *name, 
			       const char *types, IMP imp);

/*
 * ObjcUtilities_build_runtime_Objc_signature:
 *
 * This method creates a runtime objc signature which can be used 
 * to describe type for a selector *on this machine* (you need this 
 * signature for example to add a method to a class.
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
 * adding a method to a class.
 *
 */

const char *ObjcUtilities_build_runtime_Objc_signature (const char *);

#endif /* __ObjcRuntimeUtilitis_h_GNUSTEP_RUBY_INCLUDE */
