/* RIGSSelectorMapping.m - Managing mapping between Objective-C method 
   names and Rubyones

   $Id$

   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by:  Laurent Julliard <laurent@julliard-online.org>
   Date: October 2000
   
   This file is part of the GNUstep Ruby Interface Library.

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

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>


#include "RIGS.h"
#include "RIGSSelectorMapping.h"


@implementation NSSelector : NSObject

+ (id) selectorWithCString: (char *) selCString
{
  return [[NSSelector alloc] initSelectorWithCString: selCString];
}

+ (id) selectorWithString: (NSString*) selString
{
  return [[NSSelector alloc] initSelectorWithString: selString];
}

+ (id) selectorWithSEL: (SEL) sel
{
  return [[NSSelector alloc] initSelectorWithSEL: sel];
}

- (id) initSelectorWithCString: (char *) selCString
{
  self = [self init];
  
  NSDebugLog(@"Creating a new Selector for stringSEL %s",selCString);
  _sel = NSSelectorFromString([NSString stringWithCString: selCString]);
  return self;
}

- (id) initSelectorWithString: (NSString*) selString
{
  self = [self init];
  
  NSDebugLog(@"Creating a new Selector for NSStringSEL %@",selString);
  _sel = NSSelectorFromString(selString);
  return self;
}

- (id) initSelectorWithSEL: (SEL) sel
{
  self = [self init];
  
  NSDebugLog(@"Creating a new Selector for SEL for %@",NSStringFromSelector(sel));
  _sel = sel;
  return self;
}

- (SEL) getSEL
{
  return _sel;
}

@end

// Some conversion functions from Ruby names to ObjC selectors (SEL)
// They are not really realted to the NSSelector class but they fit well
// in there


NSString *
SelectorStringFromRubyName (char *name, BOOL hasArgs)
{
	id selname  = [NSString stringWithCString: name];
        
	selname = [[selname componentsSeparatedByString: @"_"]
				componentsJoinedByString: @":"];

	if([selname hasSuffix: @"="])
          selname = [selname substringToIndex: [selname length] - 1];
			
	if(hasArgs && ![selname hasSuffix: @":"])
		selname = [selname stringByAppendingString: @":"];
	
	return (selname);
}

SEL
SelectorFromRubyName (char *name, BOOL hasArgs)
{
  return NSSelectorFromString(SelectorStringFromRubyName(name, hasArgs));
}

NSString *
RubyNameFromSelector(SEL sel)
{
    return RubyNameFromSelectorString(NSStringFromSelector(sel));
}

NSString *
RubyNameFromSelectorString(NSString *name)
{
    
    name = [[name componentsSeparatedByString: @":"]
              componentsJoinedByString: @"_"];

    if([name hasSuffix: @"_"])
        name = [name substringToIndex: [name length] - 1];

    return name;
}
