#!/usr/local/bin/ruby
#
# The initial boot strap code to  for RIGS. It preloads
# some of the ObjC/GNUstep classes and sometimes
# wraps some ruby code around it.
#
# $Id$
#
#   Copyright (C) 2001 Free Software Foundation, Inc.
#
#   Written by:  Laurent Julliard <laurent@julliard-online.org>
#   Date: Aug 2001
#   
#   This file is part of the GNUstep Ruby  Interface Library.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Library General Public License for more details.
#   
#   You should have received a copy of the GNU Library General Public
#   License along with this library; if not, write to the Free
#   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
#


# If loading librigs.so and librigs_d.so (debug version)
# then say tchao bambino....
begin
    ok = require 'librigs'
rescue LoadError

    begin
	ok = require 'librigs_d'
    rescue LoadError
	puts "librigs could not be loaded!! Script aborted..."
	exit
    end

end



class Object

    #
    # Invoking AT"a string..." in Ruby will automatically generate
    # a NSString (the '@' sign can't be used as in GNUstep
    # because it is a reserved character for instance and class
    # variables. AT has no effect if String autoconversion is ON
    #
    def AT (stg)
	if ($STRING_AUTOCONVERT)
	    return stg
	else
	    return NSString.stringWithCString(stg)
	end
    end

    #
    # selector is a shortcut to NSSelector#new
    # (mimics @selector in Objective C)
    #
    def selector (selString)
	return NSSelector.new(selString)
    end
end

module Rigs

    #
    # Determine if the class is already loaded		
    # if not then load rigs/classname.rb if it exists
    # if it doesn't then just invoke Rigs.class("classname")
    #
    # - if NSxxxx top level constant defined than it means we have
    #    already gone through a full regular import from the Ruby side
    #    so there is no nedd to import again
    # - Try and load NSxxxx.rb file. If ok then return else if no Ruby code...
    # - Load the class (Rigs.class)
    # - if the NSxxxx is not defined then define it (we need to test for the
    #    existence of NSxxxx top level constant because Rigs.class goes to
    #    Objective C which then call Rigs.import again
    #
    # This mechanism makes sure that the Ruby code for a given NSxxxx
    # class is  loaded ok whether the class is imported from the Ruby side
    # with import or automagically registered from Objective C
    def Rigs.import (className)
	#puts "Entering import #{className}"
	if !(Object.const_defined? className)
	    classFile = "rigs/"+className+".rb"
	    begin
		require classFile
		#puts "Ruby code for #{className} loaded"
	    rescue LoadError
		rbClass = Rigs.class(className)
		if !(Object.const_defined? className)
		    Object.const_set(className, rbClass)
		    #puts "Objects constant #{className} set"
		end
	    end
	end

    end

end


# An example of using autoload so that the programmer
# doesn't have to make a Rigs.import. For now just show how to
# do it with a couple of classes(a class of our own). Later I might want
# to extend the list to all GNUstep classes (we need one small .rb file
# for each class (it's tedious....)
#autoload :NSSelector, "rigs/NSSelector.rb"
#autoload :NSString, "rigs/NSString.rb"
#autoload :NSMutableString, "rigs/NSString.rb"
#autoload :NSArray, "rigs/NSArray.rb"
#autoload :NSMutableArray, "rigs/NSArray.rb"

# For now just preload a reasonable set of Classes
# Other will have to be loaded manually by the user
#
#Rigs.import("NSMutableString")
#Rigs.import("NSMutableArray")
#Rigs.import("NSApplication")
#Rigs.import("NSMenu")
#Rigs.import("NSLog")

# Set it to true if you want all Ruby String arguments
# to be automatically transformed to NSString
# and returned NSString object transformed to Ruby String
$STRING_AUTOCONVERT = false

# Set it to true if you want to bothe express SELectors with
# simple strings in Ruby or conversely have an ObjC sel
# returned as a String
# In all cases you can invoke selector("selectorString:") in Ruby
# to generate a selector.
$SELECTOR_AUTOCONVERT = false
