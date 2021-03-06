# NSString.rb - Add a couple of things to the Objective C NSString class
#
#  $Id$
#
#    Copyright (C) 2001 Free Software Foundation, Inc.
#   
#    Written by:  Laurent Julliard <laurent@julliard-online.org>
#    Date: July 2001
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

NSString = Rigs.class("NSString")

module Rigs

    # Redefine some class methods
    class << NSString

	#
	# Undefine the default new method that was registered
	# from the Objective C side of RIGS. The new version of "new"
	# check the nature of the argument and
	# then transform it into a NSString or NSMutableString
	#
	remove_method :new
	def new (arg = nil)
	    if (arg.class == String)
		self.stringWithCString(arg)
	    else
		self.string
	    end
	end


	# Override availableStringEncondings so that
	# it returns a Ruby array of String encoding values instead of
	# raw ObjC pointer
	alias_method :availableStringEncodings_, :availableStringEncodings
	def availableStringEncodings
	    NSString.availableStringEncodingsAsRubyArray
	end


    end

    # Redefine some instance methods
    class NSString

	def == (string)
	    self.isEqualToString(string)
	end


	# For the moment all structures are returned as Ruby arrays
	# There is no wrapping class around NSRange, NSRect,.... If there
	# was one, each GS method returninga structure would require
	# a wrapping Ruby method to cast the returned Array into an
	# NSxxx class (It's something like 150 methods in total !!!)

	# now write a proxy method for each method returning a NSRange
	# structure
# 	alias_method :lineRangeForRange_ , :lineRangeForRange
# 	def lineRangeForRange (aRange)
# 	    puts "tototo"
# 	    ary = self.lineRangeForRange_(aRange.to_array)
# 	    NSRange.new(ary[0],ary[1])
# 	end

    end
end

#
# define specific constants (see NSString.h)
#

# String search mode
NSCaseInsensitiveSearch = 1
NSLiteralSearch = 2
NSBackwardsSearch = 4
NSAnchoredSearch = 8

# String charset encoding
#  
GSUndefinedEncoding           = 0
NSASCIIStringEncoding         = 1
NSNEXTSTEPStringEncoding      = 2
NSJapaneseEUCStringEncoding   = 3
NSUTF8StringEncoding          = 4
NSISOLatin1StringEncoding     = 5	# ISO-8859-1; West European
NSSymbolStringEncoding        = 6
NSNonLossyASCIIStringEncoding = 7
NSShiftJISStringEncoding      = 8
NSISOLatin2StringEncoding     = 9	# ISO-8859-2; East European
NSUnicodeStringEncoding       = 10
NSWindowsCP1251StringEncoding = 11
NSWindowsCP1252StringEncoding = 12	# WinLatin1
NSWindowsCP1253StringEncoding = 13	# Greek
NSWindowsCP1254StringEncoding = 14	# Turkish
NSWindowsCP1250StringEncoding = 15	# WinLatin2
NSISO2022JPStringEncoding     = 21
NSMacOSRomanStringEncoding    = 30
NSProprietaryStringEncoding   = 31

# GNUstep additions
NSKOI8RStringEncoding         = 50	# Russian/Cyrillic
NSISOLatin3StringEncoding     = 51	# ISO-8859-3; South European
NSISOLatin4StringEncoding     = 52	# ISO-8859-4; North European
NSISOCyrillicStringEncoding   = 22	# ISO-8859-5
NSISOArabicStringEncoding     = 53	# ISO-8859-6
NSISOGreekStringEncoding      = 54	# ISO-8859-7
NSISOHebrewStringEncoding     = 55	# ISO-8859-8
NSISOLatin5StringEncoding     = 57	# ISO-8859-9; Turkish
NSISOLatin6StringEncoding     = 58	# ISO-8859-10; Nordic

# Possible future ISO-8859 additions
#  NSISOThaiStringEncoding = 59		# ISO-8859-11
					# ISO-8859-12
NSISOLatin7StringEncoding     = 61	# ISO-8859-13
NSISOLatin8StringEncoding     = 62	# ISO-8859-14
NSISOLatin9StringEncoding     = 63	# ISO-8859-15; Replaces ISOLatin1
NSGB2312StringEncoding        = 56
  
# OpenStep reserved value for Unicode base 
NSOpenStepUnicodeReservedBase = 0xF400
