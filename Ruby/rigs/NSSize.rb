# NSSize- Define a fake NSSize class and methods that go with it
#
#  $Id$
#
#    Copyright (C) 2001 Free Software Foundation, Inc.
#   
#    Written by:  Laurent Julliard <laurent@julliard-online.org>
#    Date: September 2001
#  
#    This file is part of the GNUstep RubyInterface Library.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Library General Public
#    License as published by the Free Software Foundation; either
#    version 2 of the License, or (at your option) any later version.
#   
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#   
#    You should have received a copy of the GNU Library General Public
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
#

class NSSize

    # Define a "fake" new method that simply returns 
    # an array
    def NSSize.new(width, height)
	if ( !width.kind_of?(Numeric) )
	    raise ArgumentError,"NSSize 'width' is not a number", caller
	end
	if ( !height.kind_of?(Numeric) )
	    raise ArgumentError,"NSSize 'height' not an number", caller
	end

	[width, height]
    end

end

class Array

    def equalToSize? (aSize)
	self == aSize
    end

    def emptySize?
	(self.width == 0) || (self.height == 0)
    end

end

NSZeroSize = NSSize.new(0,0)
