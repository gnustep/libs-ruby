#!/usr/local/bin/ruby
#
# Ruby script to test the GUI part of RIGS
#
#   $Id$
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

# You can drag all Foundation and AppKit Classes at once or ....
require 'Foundation'
require 'AppKit'

#... get only those you need  one by one
#Rigs.import("NSApplication")
#Rigs.import("NSGraphicsContext")
#Rigs.import("NSWindow")
#Rigs.import("NSButton")
#Rigs.import("NSProcessInfo")
#Rigs.import("NSMenu")
#Rigs.import("NSSelector")
#Rigs.import("NSString")

$STRING_AUTOCONVERT = true
$SELECTOR_AUTOCONVERT = false

class MyDelegate
	
    # This is an example of how to declare method signature 
    # used in your class. Use the reserved @@objc_types to 
    # do that. In most cases this is not necessary to explicitely
    # declare method signatures unless ObjC return type or arguments
    # have an usual size (like a double or short)
    #
    # In the example below the @@objc_types could have been omitted
    # because RIGS will guess all signature OK
    #@@objc_types = {
#	"printHello" => "v@:@",
#	"applicationWillFinishLaunching" => "v@:@", # return void
#	"applicationShouldTerminate" => "C@:@"    # return a boolean
#    }
    def initialize 
	@window = NSWindow.alloc
    end

    def printHello(sender)
	#print "Class of sender received by printHello: ",sender.type,"\n"
	puts "Hello!"
    end

    def createMenu
	menu = NSMenu.new
	infoMenu = NSMenu.new

	# SELECTOR_AUTOCONVERT is false but you can still pass a selector
	# as a string. Knowing that ObjC method is expecting a SEL argument
	# RIGS will automatically make the conversion
	infoMenu.addItemWithTitle_action_keyEquivalent("Info Panel...",
	           "orderFrontStandardInfoPanel:", "")

	infoMenu.addItemWithTitle_action_keyEquivalent("Help...",
	           selector("orderFrontHelpPanel:"),"?")

	menuItem = menu.addItemWithTitle_action_keyEquivalent("Info...",nil,"")

	menu.setSubmenu_forItem(infoMenu, menuItem)

	menu.addItemWithTitle_action_keyEquivalent("Print Hello...",
	           selector("printHello:"),"")

	menu.addItemWithTitle_action_keyEquivalent("Quit",
	           selector("terminate:"),"q")
	
	$NSApp.setMainMenu(menu)
    end

    def createWindow

	styleMask = NSTitledWindowMask | NSClosableWindowMask |
	    NSMiniaturizableWindowMask | NSResizableWindowMask

	button = NSButton.new
	button.setTarget(self)
	button.setAction( selector("printHello:"))
	button.setTitle("Print Hello!")
	button.sizeToFit()

	buttonSize = button.frame.size

#	rect = NSRect.new(100, 100 , buttonSize.width, buttonSize.height)
	rect = NSRect.new(0, 0, 400, 200)

	@window = NSWindow.alloc
	@window = @window.initWithContentRect_styleMask_backing_defer \
	                 (rect, styleMask, NSBackingStoreRetained, false)

	@window.setTitle("Test window with one giant button!")
	@window.setContentView (button)

    end

    def applicationWillFinishLaunching (notification)
	createMenu
	createWindow
    end

    def applicationDidFinishLaunching (notification)
	@window.center()
	@window.makeKeyAndOrderFront(self)
    end

    def applicationShouldTerminate (notification)
	puts "That's the end of it! Bye,bye..."
	return true
    end
end

# Here it is not necessary to register the MyDelegate class with ObjC
# because it is passed as an argument to the objC method setDelegate
# and therefore it is automatically intercepted and register with ObjC
# 
#Rigs.register(MyDelegate)

# Like in GNUStep the NSApp global variable is automatically set up
# after a call to sharedApplication
NSApplication.sharedApplication

$NSApp.setDelegate(MyDelegate.new)

# Calling NSApplicationMain is better because it puts all the 
# Process and Bundle information in place
#$NSApp.run
NSApplicationMain()

exit
