#   NSApplicationTest: test of Rigs::NSApplication
#
#    Copyright (C) 2000 Free Software Foundation, Inc.
#
#    Author:  Laurent Julliard <laurent@julliard-online.org>
#             (inspired from Nicola Pero's JIGS test file)
#    Date: September 2001
#  
#    This file is part of GNUstep.
#  
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation either version 2 of the License, or
#    (at your option) any later version.
#  
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#  
#    You should have received a copy of the GNU General Public License
#    along with this program if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

require 'rigs'
Rigs.import("NSApplication")

class NSApplicationTest

    @@state = 1
    @failed = false

    def applicationWillFinishLaunching (notification)
	return if @failed

	puts " *1* applicationWillFinishLaunching called"
	if (@@state != 1)
	    puts " ==> Test failed - this should have been the 1th step (not  #{@@state})"
	    @failed = true
	    $NSApp.terminate(self)
	    exit 1
	end

	checkNotification(notification)
	@@state = 2
    end
    
    def applicationDidFinishLaunching (notification)
	return if @failed

	puts " *2* applicationDidFinishLaunching called"
	if (@@state != 2)
	    puts " ==> Test failed - this should have been the 2nd step"
	    @failed = true
	    $NSApp.terminate(self)
	    exit 1
	end

	checkNotification(notification)
	@@state = 3

	# Launching finished ok, now start the terminate sequence
	$NSApp.terminate(self)

    end

    def applicationShouldTerminate (sender)
	return if @failed

	puts " *3* applicationShouldTerminate called"
	if (@@state != 3)
	    puts " ==> Test failed - this should have been the 3rd step"
	    @failed = true
	    return true
	end

	@@state = 4
	return true
    end
    
    def applicationWillTerminate (notification)
	return if @failed

	puts " *4* applicationWillTerminate called"
	if (@@state != 4)
	    puts " ==> Test failed - this should have been the 2nd step"
	    @failed = true
	    $NSApp.terminate(self)
	    exit 1
	end

	puts "==> Test passed <AFAIK>"
	@@state = 5
    end

    def checkNotification (notification)

	if (notification == nil)
	    puts " ==> Test failed - null notification at state #{@@state}"
	    @failed = true
	    $NSApp.terminate(null)
	    exit 1
	end
	
	sender = notification.object()

	if (sender != $NSApp)
	    puts " Test failed - object of notification is not correct"
	    @failed = true
	    $NSApp.terminate(nil)
	    exit 1
	end
    end

end

NSApplication.sharedApplication

$NSApp.setDelegate(NSApplicationTest.new)

$NSApp.run

exit
