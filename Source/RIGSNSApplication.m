/* RIGSNSApplication.m - Some additional code to properly wrap the
   NSApplication class in Ruby

   $Id$

   Copyright (C) 2001 Free Software Foundation, Inc.
   
   Written by:  Laurent Julliard <laurent@julliard-online.org>
   Date: August 2001
   
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>


#include "RIGS.h"
#include "RIGSCore.h"
#import "RIGSNSApplication.h"

// Ruvy view of the NSApp global GNUstep variable
static VALUE rb_NSApp = Qnil;

// Our own argc and argv rebuilt  from Ruby ARGV ($*)
static char **ourargv;
static int ourargc;

extern char** environ;
//extern char** argv;
//extern char** argc;
extern void _gnu_process_args(int argc, char *argv[], char *env[]);

VALUE _RIGS_get_NSApp(ID rb_id, VALUE *data, global_entry_ptr entry) 
{
  DATA_PTR(rb_NSApp) = NSApp;
  return rb_NSApp;
}

void _RIGS_set_NSApp(VALUE value, ID rb_id, VALUE *data, global_entry_ptr entry) 
{
  
  Data_Get_Struct(value, NSApplication, NSApp);
  DATA_PTR(rb_NSApp) = NSApp;
  NSDebugLog(@"Setting NSApp to 0x%lx", NSApp);
  
}

void
_RIGS_rebuild_argc_argv(VALUE rb_argc, VALUE rb_argv)
{
    int i;

    // +1 in arcg for the script name that is not in ARGV in Ruby
    ourargc = FIX2INT(rb_argc)+1;
    
    ourargv = malloc(sizeof(char *) * ourargc);
    ourargv[0] = STR2CSTR(rb_gv_get("$0"));


    /* Can't use NSDebugLog before NSProcessInfo is initialized
       at least on Windows platform (Linux is ok). So use printf */
    NSDebugLog(@"Argc=%d\n",ourargc);
    NSDebugLog(@"Argv[0]=%s\n",ourargv[0]);
     
    for (i=1;i<ourargc; i++) {
        ourargv[i] = STR2CSTR(rb_ary_entry(rb_argv,(long)(i-1)));     
        NSDebugLog(@"Argv[%d]=%s\n",i,ourargv[i]);
    }
    
}



/* This function can be passed 0 argument or 2.
   - If no argument is given then we rebuild argc and argv from
      Ruby $* AND $0 global variables
   - If 2 argument are passed they are argc in the form of a FIXNUM
     and argv in the form of a Ruby array (unlike C we don't want $0,
     the script name in argv[0]

The goal of this function is twofold:

  1) Update the NSProcessInfo information with real argc, argv and env
    (argv needs to be modified so that argv[0] reflects the ruby script
    path as a process name instead of simply "ruby"

  2) Modify the Main NSBundle to reflect the ruby script executable path of
    because otherwise the executable path always says /usr/local/bin/ruby
    and NSBundle never finds the application Resources (plist files, etc...)

*/
VALUE _NSApplicationMainFromRuby(int arg_count, VALUE *arg_values, VALUE self) 
{
  VALUE rb_argc;
  VALUE rb_argv;
  id pool = [NSAutoreleasePool new];

  
    NSDebugLog(@"Arguments in NSProcessInfo before rebuild: %@",[[NSProcessInfo processInfo] arguments]);


    if (arg_count == 0) {

      rb_argv = rb_gv_get("$*");
      rb_argc = INT2FIX(RARRAY(rb_argv)->len);

    } else if (arg_count == 2) {

      rb_argc = arg_values[0];
      rb_argv = arg_values[1];
      if ( (TYPE(rb_argc) != T_FIXNUM) || (TYPE(rb_argv) != T_ARRAY) ) {
        rb_raise(rb_eTypeError, "invalid type of arguments (must be an Integer and an Array)");
      }
      
    } else {
        rb_raise(rb_eArgError, "wrong # of arguments (%d for 0 or 2)", arg_count);
    }

    // Rebuild argv and argc from Ruby ARGV array
    _RIGS_rebuild_argc_argv(rb_argc,rb_argv);
        
    // (Re) Initialize a GNUstep Processinfo structure to take into account the 
    // the debug flag given on the command line (--GNU-Debug=dflt)
    // We cannot use NSProcessInfo initializeWithArguments: because it
    // was called at the very beginning by the NSProcessInfo +load method
    // and calling it a second time has no effect (See NSApplication.m)
    // (FIXME?? : the only work around I have found is to call the internal
    // function _gnu_process_args again
    _gnu_process_args(ourargc,ourargv,environ);
    
    // Calling NSBundle +initialize again
    // doesn't work because _executable_path is taken from the proc fs
    // filesystem which always says /usr/local/bin/ruby
    // And NSBundle mainBundle relies on _executable_path so... we are stuck
    //[NSBundle initialize];
    //[NSBundle mainBundle];

    // So basically redo here what the NSBundle +mainBundle does 
    // but with  the executable path taken from argv[0]
    {
      NSString *path, *s;
      NSBundle *b;
      
      
      // Get access to the current main bundle
      b = [NSBundle mainBundle];
      NSDebugLog(@"Current Main Bundle path: %@", [b bundlePath]);

      path = [[[NSProcessInfo processInfo] arguments] objectAtIndex: 0];
      path = [NSBundle _absolutePathOfExecutable: path];
      path = [path stringByDeletingLastPathComponent];

      // For some reason _library_combo, _gnustep_target_* methods are not
      // visible (why?) so simply strip the 3 path components assuming they are
      // here (FIXME?)
      s = [path lastPathComponent];
      //if ([s isEqual: [NSBundle _library_combo]])
	path = [path stringByDeletingLastPathComponent];
      /* target os */
      s = [path lastPathComponent];
      //if ([s isEqual: [NSBundle _gnustep_target_os]])
	path = [path stringByDeletingLastPathComponent];
      /* target cpu */
      s = [path lastPathComponent];
      //if ([s isEqual: [NSBundle _gnustep_target_cpu]])
	path = [path stringByDeletingLastPathComponent];
      /* object dir */
      s = [path lastPathComponent];
      if ([s hasSuffix: @"_obj"])
	path = [path stringByDeletingLastPathComponent];

      NSDebugLog(@"New generated path to application: %@", path);
      
      /* We do alloc and init separately so initWithPath: knows
          we are the _mainBundle */
      //_mainBundle = [NSBundle alloc];
      [b initWithPath:path];
    
  
      NSDebugLog(@"New Main Bundle path: %@", [[NSBundle mainBundle] bundlePath]);
    }
      
    NSDebugLog(@"Arguments in NSProcessInfo after rebuild: %@",[[NSProcessInfo processInfo] arguments]);

    [pool release];
    
    return INT2FIX(NSApplicationMain(ourargc,(const char **)ourargv));
            
}


@implementation NSApplication ( RIGSNSApplication )

+ (BOOL) finishRegistrationOfRubyClass: (VALUE) ruby_class
{

  // We need to define the global variable $NSApp in Ruby
  // and make it a variable hooked to the Objective C NSApp
  
  // if global variable is already defined then give up (this
  // method should only be called once !
  if ( rb_NSApp != Qnil ) {
    NSLog(@"finishRegistrationOfRubyClass: called more than once for NSApplication! Doing nothing...");
    return NO;
  }

  // Create a Ruby DATA structure embedding the NSApp global variable
  // and make it available as $NSApp global variable in Ruby.
  rb_NSApp = Data_Wrap_Struct(ruby_class, 0, 0, nil);
  rb_define_hooked_variable("$NSApp",&rb_NSApp,
                            _RIGS_get_NSApp,_RIGS_set_NSApp);

  // Also define a global Ruby method equivalent to NSApplicationMain
  rb_define_global_function("NSApplicationMain", _NSApplicationMainFromRuby,-1);

  return YES;

}

@end
      
