#   NSWindowTest: test of Rigs::NSWindow
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
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#  
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#  
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

require 'rigs'
Rigs.import("NSApplication")
Rigs.import("NSGraphicsContext")
Rigs.import("NSWindow")
Rigs.import("NSProcessInfo")

class NSWindowTest

    def initialize 
	@window = NSWindow.alloc
    end

    def applicationWillFinishLaunching (notification)

	rect = NSRect.new(0, 0, 400, 200)
	styleMask = NSTitledWindowMask | NSClosableWindowMask |
	    NSMiniaturizableWindowMask | NSResizableWindowMask

	@window.initWithContentRect_styleMask_backing_defer \
	                 (rect, styleMask, NSBackingStoreRetained, false)
	@window.setTitle("GNUstep GUI working from Ruby")
    end
  
    def applicationDidFinishLaunching (notification)
	@window.center()
	@window.makeKeyAndOrderFront(self)
    end

    def applicationShouldTerminateAfterLastWindowClosed (application)
	true
    end
    
end

  
# main
NSProcessInfo.processInfo.setProcessName("NSWindowTest")

application = NSApplication.sharedApplication
windowTest = NSWindowTest.new

application.setDelegate(windowTest)

application.run
 
