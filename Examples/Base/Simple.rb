#!/usr/local/bin/ruby
#
# Ruby script to test the non GUI part of RIGS
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

require 'rigs'
Rigs.import("NSString")
Rigs.import("NSMutableString")
Rigs.import("NSArray")
Rigs.import("NSMutableArray")

$STRING_AUTOCONVERT = false
$SELECTOR_AUTOCONVERT = false

# print Rigs version
puts "Rigs Version : #{Rigs::VERSION}"

# test that ObjC/GNUstep exceptions are redirected to Ruby
# this one is raised because a is initialized twice.
begin
a = NSString.new
a.initWithCString("Another init value. One too much...")

rescue NSInternalInconsistencyException => reason
    print "Exception caught! No fear we did it on purpose :-)\n"
    print "Reason is : '#{reason}'\n"

end

# create some strings objects
b = NSString.stringWithCString("GNUstep for ever")
c = NSMutableString.stringWithCString("GNUstep for a while")
f = NSString.stringWithCString("3.25")

# Use the ruby defined AT shorcut to create a NSString
# (equivalent to ObjC @"...")
d = AT"String created with the AT shorcut"

print "a length =",a.length,"\n"
print "c length =",c.length,"\n"
print "d length =",d.length,"\n"
print "b length =",b.length,"\n"

puts b.capitalizedString.cString
puts b.uppercaseString.cString
puts d.uppercaseString.cString

print "a isEqualToString a: ", a.isEqualToString(a),"\n"
print "b isEqualToString c: ", b.isEqualToString(c),"\n"
print "d isEqualToString c: ", d.isEqualToString(c),"\n"

# These 2 doesn't work yet
print "f as a floating point number = ",f.floatValue,"\n"
print "d as a double floating point number = ",f.doubleValue,"\n"

# Fill up a NS Array with both native Ruby objects and
# ObjC objects - (Test native Ruby objects wrapping)
array = NSMutableArray.new
rbarr = [1,2, "2345", nil]
rbhash = {"Saint Emilion" => "Bordeaux",
          "Meursault" => "Bourgogne",
          "Pommard" => "Bourgogne"}
array.addObject(rbarr)
array.addObject(b)
array.addObject(rbhash)
printf "There are %d elements in the NSArray object\n",array.count

# Test that 'description' method is working fine
# RIGS transparently maps 'description' method to to_s ruby method 
print "Array Description:\n",array.description.cString,"\n"

# Test a ruby object is  wrapped only once and we keep the same
# reference for the same Ruby object
print "Is rbhash in array? Answer: ",(array.containsObject(rbhash) ? "yes":"no"),"\n"

# Test Ruby Object unwrapping
print "2nd element of array is: ",array.objectAtIndex(2),"\n"
 
puts "--End--"
