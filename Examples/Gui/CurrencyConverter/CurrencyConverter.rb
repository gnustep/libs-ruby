#!/usr/bin/env ruby
#
#  CurrencyConverter.m: A mini over-commented sample GNUstep app 
#
#  Copyright (c) 1999 Free Software Foundation, Inc.
#  
#  Author: Nicola Pero
#  Date: November 1999
#
#  Converted to Ruby by Laurent Julliard
#  Date: September 2001
#
#  This sample program is part of GNUstep.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
#
# This mini sample program documents using text fields. 
#
# Layout is done with GSHbox, GSVbox.  
# See Calculator.app for an example of window layout done without 
# using GSVbox & GSHbox.
#
#
#
#  I took the idea of writing this example code from an old GNUstep project 
#  by Michael S. Hanni, but everything was coded from scratch. 
#

require 'rigs'
require 'Foundation'
require 'AppKit'

$STRING_AUTOCONVERT = true


# Text to be displayed in the labels
$FieldString = [ 
    "Amount in other currency:",
    "EUROs to convert:", 
    "Exchange rate per 1 EURO:"
]

# Implementation of our custom class.
class CurrencyConverter
    
    def initialize
	# Our two instance variables
	@field = []
	@window = NSWindow.alloc
    end

    def createMenu

	mainMenu = NSMenu.new
	editMenu = NSMenu.new

	mainMenu.addItemWithTitle_action_keyEquivalent("Info...",
		selector("orderFrontStandardInfoPanel:"),"")

	# Add the "Edit" Submenu
	menuItem = mainMenu.addItemWithTitle_action_keyEquivalent("Edit", nil,"")

	mainMenu.setSubmenu_forItem(editMenu, menuItem)
	
	# The object which should receive the messages cut:, copy:, paste: is not 
	# specified, so that the library will have to determine it at run time. 
	# At first, it will (try to) send them to the 'first responder' 
	# -- the object which is receiving keyboard input.  
	# In our case that is precisely what we want, since the first responder 
	# is the NSText being edited (which knows how to handle cut:, copy:, 
	# paste:), if any.  
	editMenu.addItemWithTitle_action_keyEquivalent("Cut",selector("cut:"),"x")
	editMenu.addItemWithTitle_action_keyEquivalent("Copy",selector("cut:"),"c")
	editMenu.addItemWithTitle_action_keyEquivalent("Paste",selector("paste:"),"v")
	editMenu.addItemWithTitle_action_keyEquivalent("Select All",selector("selectAll:"),"a")
	
	# Hide MenuItem
	mainMenu.addItemWithTitle_action_keyEquivalent("Hide", selector("hide:"),"")
	
	# Quit MenuItem
	mainMenu.addItemWithTitle_action_keyEquivalent("Quit", selector("terminate:"),"")
	$NSApp.setMainMenu(mainMenu)

	# The default title @"Currency Converter" is a bit too long
	mainMenu.setTitle("CurrConv")
    end

    def createWindow

	# Create a vertical box (NB: Things are packed in the box 
	# from bottom to top)
	windowVbox = GSVbox.new
	windowVbox.setBorder 0
	windowVbox.setDefaultMinYMargin 0

	# Result field
	hbox = GSHbox.new
	hbox.setDefaultMinXMargin 10
	hbox.setBorder 10

	label = NSTextField.new
	label.setSelectable false
	label.setBezeled false
	label.setDrawsBackground false
	label.setStringValue $FieldString[0]
	label.sizeToFit
	label.setAutoresizingMask NSViewHeightSizable
	hbox.addView_enablingXResizing(label, false)

	@field[0] = NSTextField.new
	@field[0].setSelectable true
	@field[0].setEditable false
	@field[0].setBezeled true
	@field[0].setBackgroundColor(NSColor.controlBackgroundColor)
	@field[0].setDrawsBackground true
	# Use automatic height
	@field[0].sizeToFit
	# But set width to 100
	size = @field[0].frame.size
	size.width = 100
	@field[0].setFrameSize size
	@field[0].setAutoresizingMask NSViewWidthSizable
	# Saying nothing means enablingXResizing: YES
	hbox.addView @field[0]

	hbox.setAutoresizingMask NSViewWidthSizable
	windowVbox.addView hbox

	#
	# Separator
	#
	windowVbox.addSeparator
  
	#
	# Upper part of the window
	#
	formVbox = GSVbox.new
	formVbox.setBorder 10
	formVbox.setDefaultMinYMargin 10

	(1..2).each do |i|

	    # We are doing it the hard way, without NSForm, to show how to do
	    # more generally to pack things and objects
	    hbox = GSHbox.new
	    hbox.setDefaultMinXMargin 10

	    label = NSTextField.new
	    label.setSelectable false
	    label.setBezeled false
	    label.setDrawsBackground false
	    label.setStringValue $FieldString[i]
	    label.sizeToFit
	    label.setAutoresizingMask NSViewHeightSizable
	    hbox.addView_enablingXResizing(label, false)

	    @field[i] = NSTextField.new
	    @field[i].setEditable true
	    @field[i].setBezeled true
	    @field[i].setDrawsBackground true
	    # Use automatic height
	    @field[i].sizeToFit
	    # But set width to 100
	    size = @field[i].frame.size
	    size.width = 100
	    @field[i].setFrameSize size
	    @field[i].setAutoresizingMask NSViewWidthSizable
	    hbox.addView @field[i]

	    hbox.setAutoresizingMask NSViewWidthSizable
	    formVbox.addView hbox

	end


	# Link the editable fields so the user may move between them
	# pressing TAB (Important: Remember to always send these messages
	# *after* you have created the objects you are referring to)
	@field[1].setNextText @field[2]
	@field[2].setNextText @field[1]

	# Ask to receive interesting messages concerning what's happening 
	# to the fields.  We are interested only in [-controlTextDidEndEditing:]
	@field[1].setDelegate self
	@field[2].setDelegate self

	formVbox.setAutoresizingMask NSViewWidthSizable
	windowVbox.addView formVbox

	#
	# Window
	#
	winFrame = NSRect.new
	winFrame.size = windowVbox.frame.size
	winFrame.origin = NSPoint.new(100, 100)

	# Now we can make the window of the exact size  
	# NB: Note that we do not autorelease the window
	styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask |
	    NSResizableWindowMask
	@window.initWithContentRect_styleMask_backing_defer(winFrame,
			styleMask, NSBackingStoreBuffered, true)
	
	@window.setTitle "CurrencyConverter.app"
	@window.setContentView windowVbox
	minSize = NSWindow.frameRectForContentRect_styleMask(
				winFrame, @window.styleMask).size
	@window.setMinSize minSize

	# Trick to forbid vertical resizing
	@window.setResizeIncrements NSSize.new(1, 100000)
	return self
    end


    def controlTextDidEndEditing (aNotification)
	# Read values
	euros = @field[2].floatValue
	rate = @field[1].floatValue
	
	# Compute total
	total = euros * rate
	
	# Display total
	@field[0].setFloatValue total
    end

    def applicationWillFinishLaunching (notification)
	createMenu
	createWindow
    end

    def applicationDidFinishLaunching (aNotification)
	@window.orderFront self
    end

end


# Main. Execution starts from here.

# Get the object representing our application.
# the $NSApp global variable also contains the app object
app = NSApplication.sharedApplication

# Create and initializes an instance of our custom object.
converter = CurrencyConverter.new
   
# Set our custom object instance as the application delegate. 
# This means that 'converter' will receive certain messages 
# (documented in the doc) before/after important events for the app 
# life, such as starting, ending, closing last window, etc.
# In this context, we are interested in receiving the 
# [-applicationDidFinishLaunching:] message.
app.setDelegate(converter)

# Finally, all is ready to run our application.
NSApplicationMain()

exit
