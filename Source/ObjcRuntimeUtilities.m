/* ObjcRuntimeUtilities.m - Utilities to add classes and methods 
   in the Objective-C runtime, at runtime.

   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by:  Nicola Pero <nicola@brainstorm.co.uk>
   Date: June 2000
   
   This file is part of the GNUstep Java Interface Library.

   It was partially derived by: 

   --
   gg_class.m - interface between guile and GNUstep
   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: September 1998

   This file is part of the GNUstep-Guile Library.

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

/*
 *	NOTE - OBJC_VERSION needs to be defined to be the version of the
 *	Objective-C runtime you are using.  You can find this in the file
 *	'init.c' in the GNU objective-C runtime source.
 */
#import "ObjcRuntimeUtilities.h"
#import <objc/runtime.h>
#include <string.h>

BOOL ObjcUtilities_new_class(const char *name, 
			     const char *superclassName, 
			     int ivarNumber, ...)
{
  
  NSValue *classPointer = nil;
  NSArray *classes = nil;
  NSMutableDictionary *ivarDictionary = [NSMutableDictionary dictionary];
  NSString *className = [NSString stringWithUTF8String: name];
  NSString *superClassName = [NSString stringWithUTF8String: superclassName];

  if (objc_getClass (name) != Nil || objc_getClass (superclassName) == Nil)
    {
      return NO;
    }
  
  // Build ivar dictionary....
  if (ivarNumber > 0)
    {
      va_list  ap;
      int i = 0;
      
      // Prepare ivars
      va_start(ap, ivarNumber);      
      for (i = 0; i < ivarNumber; i++)
	{
	  const char *ivarNameCString = va_arg (ap, char *);
	  const char *ivarTypeCString = va_arg (ap, char *);
	  NSString *ivarName = [NSString stringWithUTF8String: ivarNameCString];
	  NSString *ivarType = [NSString stringWithUTF8String: ivarTypeCString];

	  [ivarDictionary setObject: ivarType
			     forKey: ivarName];
	}
      va_end(ap);
    }

  classPointer = GSObjCMakeClass(className,
				 superClassName,
				 ivarDictionary);

  if (classPointer == nil)
    {
      return NO;
    }

  classes = [NSArray arrayWithObject: classPointer];
  GSObjCAddClasses(classes);

  return (objc_getClass (name) != Nil);
}

BOOL ObjcUtilities_add_method(Class class,
			      const char *name,
			      const char *types,
			      IMP imp)
{
  SEL selector;
  
  selector = GSSelectorFromNameAndTypes(name, types);
  if (selector == NULL)
    {
      selector = sel_registerName(name);
    }
  
  return class_addMethod(class, selector, imp, types);
}

const char *ObjcUtilities_build_runtime_Objc_signature(const char *types)
{
  NSMethodSignature *sig;
  
  sig = [NSMethodSignature signatureWithObjCTypes: types];
  if (sig == nil)
    {
      return NULL;
    }

  return types;
}





