# NSString.rb - Add a couple of things to the Objective C NSString class
#    Copyright (C) 2001 Free Software Foundation, Inc.
   
#    Written by:  Laurent Julliard <laurent@julliard-online.org>
#    Date: July 2001
   
#    This file is part of the GNUstep RubyInterface Library.

#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Library General Public
#    License as published by the Free Software Foundation; either
#    version 2 of the License, or (at your option) any later version.
   
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
   
#    You should have received a copy of the GNU Library General Public
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

NSString = Rigs.class("NSString")

module Rigs

    # undefine the default new method that was registered
    # from the Objective C side of RIGS
    class << NSString
	remove_method :new
    end
    
    class NSString
	
	#
	# Now redefine the new method. If new has a Ruby string as argument
	# then transform it into a NSString or NSMutableString
	#
	def NSString.new (arg = nil)
	    if (arg.class == String)
		return self.stringWithCString(arg)
	    else
		return self.string
	    end
	end

	def == (string)
	    return self.isEqualToString(string)
	end

    end

end
