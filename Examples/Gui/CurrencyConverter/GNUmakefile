#   GNUmakefile: makefile for FirstApp.app
#   Can be used as a model for other GNUstep applications
#   written in Ruby
#
#   Copyright (C) 2001 Free Software Foundation, Inc.
#
#   Author:  Laurent Julliard <laurent@julliard-online.org>
#   Date: Sep 2001
#   
#   This file is part of GNUstep.
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

include $(GNUSTEP_MAKEFILES)/common.make

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_USER_ROOT)

APP_NAME = CurrencyConverter

#FIXME? Can we avoid that? This is just to give gcc something
# to compile and link
$(APP_NAME)_OBJC_FILES = fake.m

$(APP_NAME)_RESOURCE_FILES = CurrencyConverterIcon.tiff
$(APP_NAME)_APPLICATION_ICON = CurrencyConverterIcon.tiff

MAIN_RUBY_FILE = CurrencyConverter.rb
# ADDITIONAL_RUBY_FILES = 

include $(GNUSTEP_MAKEFILES)/application.make

include GNUmakefile.postamble
