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
#define	OBJC_VERSION	8

#include "ObjcRuntimeUtilities.h"
#include <string.h>

#ifndef objc_EXPORT
#if libobjc_ISDLL /* linking against DLL version of libobjc */
#  define objc_EXPORT  extern __declspec(dllimport)
#else 
#  define objc_EXPORT  extern
#endif
#endif

BOOL ObjcUtilities_new_class (const char *name, 
			      const char *superclassName, 
			      int ivarNumber, ...)
{
  objc_EXPORT void __objc_exec_class (void *module);
  objc_EXPORT void __objc_resolve_class_links ();
  Module_t module;
  Symtab_t symtab;
  Class super_class;
  Class new_class;
  int ivarsize;
  
  //
  // Check that the name for the new class isn't already in use.
  //
  if (objc_lookup_class (name) != nil) 
    {
      return NO;
    }

  //
  // Check that the superclass exists.
  //
  super_class = objc_lookup_class (superclassName);
  if (super_class == nil)
    {
      return NO;
    }

  //
  // Prepare a fake module containing only this class.
  //
  module = objc_calloc (1, sizeof (Module));
  module->version = OBJC_VERSION;
  module->size = sizeof (Module);
  module->name = objc_malloc (strlen (name) + 15);
  strcpy ((char*)module->name, "GNUstep-Proxy-");
  strcat ((char*)module->name, name);
  module->symtab = objc_calloc (1, sizeof (Symtab));
  
  symtab = module->symtab;
  symtab->sel_ref_cnt = 0;
  symtab->refs = 0;
  symtab->cls_def_cnt = 1; // We are defining a single class.
  symtab->cat_def_cnt = 0; // But no categories 
  // Allocate space for two classes (the class and its meta class)
  symtab->defs[0] = objc_calloc (2, sizeof (struct objc_class));
  symtab->defs[1] = 0;    // NULL terminate the list.
  
  //
  //	Build class structure.
  //

  // Class
  new_class = (Class)symtab->defs[0];

  // NB: There is a trick here. 
  // The runtime system will look up the name in the following string,
  // and replace it with a pointer to the actual superclass structure.
  // This also means the type of pointer will change, that's why we 
  // need to force it with a (void *)
  new_class->super_class = (void *)superclassName;

  new_class->name = objc_malloc (strlen (name) + 1);
  strcpy ((char*)new_class->name, name);
  new_class->version = 0;
  new_class->info = _CLS_CLASS;
  ivarsize = super_class->instance_size;

  if (ivarNumber > 0)
    {
      // Prepare ivars
      va_list  ap;
      struct objc_ivar *ivar;
      int size, i;

      size = sizeof (struct objc_ivar_list);
      size += (ivarNumber - 1) * sizeof (struct objc_ivar);

      new_class->ivars = (struct objc_ivar_list*) objc_malloc (size);
      new_class->ivars->ivar_count = ivarNumber;
      
      va_start (ap, ivarNumber);
      
      ivar = new_class->ivars->ivar_list;
      
      for (i = 0; i < ivarNumber; i++)
	{
	  char *name = strdup (va_arg (ap, char *));
	  char *type = strdup (va_arg (ap, char *));
	  
	  int	align;
	  
	  ivar->ivar_name = name;
	  ivar->ivar_type = type;
      
	  align = objc_alignof_type (ivar->ivar_type); // pad to alignment
	  ivarsize = align * ((ivarsize + align - 1) /align); // ROUND
	  ivar->ivar_offset = ivarsize;
	  ivarsize += objc_sizeof_type (ivar->ivar_type);
	  ivar++;
	}
      va_end (ap);
    }
  
  new_class->instance_size = ivarsize;
  
  // Meta class
  new_class->class_pointer = &new_class[1];
  new_class->class_pointer->super_class = (void *)superclassName;
  new_class->class_pointer->name = new_class->name;
  new_class->class_pointer->version = 0;
  new_class->class_pointer->info = _CLS_META;
  new_class->class_pointer->instance_size 
    = super_class->class_pointer->instance_size;

  // Insert our new class into the runtime.
  __objc_exec_class (module);
  __objc_resolve_class_links();

  return YES;
}

MethodList *ObjcUtilities_alloc_method_list (int count)
{
  MethodList *ml;
  int extra;

  extra = (sizeof (struct objc_method)) * (count - 1);
  ml = objc_calloc (1, sizeof(MethodList) + extra);
  ml->method_count = count;  
  return ml;
}

void ObjcUtilities_insert_method_in_list (MethodList *ml, 
					  int index, const char *name, 
					  const char *types, IMP imp)
{
  Method *method;

  method = &(ml->method_list[index]);
  method->method_name = (void *)strdup (name);
  method->method_types = strdup (types);
  method->method_imp = imp;
}

const char *ObjcUtilities_build_runtime_Objc_signature (const char 
							       *types)
{
  NSMethodSignature *sig;
  
  sig = [NSMethodSignature signatureWithObjCTypes: types];
  
#if defined GNUSTEP_BASE_VERSION || defined(LIB_FOUNDATION_LIBRARY)
  return [sig methodType];
#else
# error "Don't know how to get method signature on this platform!"
#endif  
}

void ObjcUtilities_register_method_list (Class class, MethodList *ml)
{
  objc_EXPORT void class_add_method_list (Class class, MethodList_t list);
  objc_EXPORT objc_mutex_t __objc_runtime_mutex;
  
  objc_mutex_lock (__objc_runtime_mutex);
  class_add_method_list (class, ml);
  objc_mutex_unlock (__objc_runtime_mutex);
}






