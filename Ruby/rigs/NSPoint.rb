# NSPoint- Define a fake NSPoint class and methods that go with it
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

class NSPoint

    # Define a "fake" new method that simply returns 
    # an array
    def NSPoint.new(x,y)
	if ( !x.kind_of?(Numeric) )
	    raise ArgumentError,"NSPoint 'x' is not a number", caller
	end
	if ( !y.kind_of?(Numeric) )
	    raise ArgumentError,"NSPoint 'y' not an number", caller
	end

	[x,y]
    end

end

class Array

    def equalToPoint? (aPoint)
	self == aPoint
    end

    def distanceToPoint (aPoint)
	Math.sqrt((self.x - aPoint.x)**2 + (self.y - aPoint.y)**2)
    end

    def mouseInRect (aRect, flipped)
	if (flipped)
	    ( (self.x >= aRect.minX) && (self.y >= aRect.minY) &&
	      (self.x < aRect.maxX)  && (self.y < aRect.maxY) ) 
	else
	    ( (self.x >= aRect.minX) && (self.y > aRect.minY) &&
	      (self.x < aRect.maxX)  && (self.y <= aRect.maxY) ) 
	end
    end

    def pointInRect?(aRect)
	self.mouseInRect?(aRect, true)
    end
end

NSZeroPoint = NSPoint.new(0,0)
