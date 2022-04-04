#
#  Makefile for GNUstep Ruby Interface Library, Objective C part 
#
# $Id$
#
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Written by: Laurent Julliard (<laurent@julliard-online.org>)
#
#  This file is part of the GNUstep Ruby Interface Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA
#

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = librigs

VERSION = 0.2.2

# Dynamically determine where the things must be installed
# in Ruby
RUBY_ARCH_DIR := $(shell ruby -rrbconfig -e 'print RbConfig::CONFIG["archdir"]')

RUBY_SITE_ARCH_DIR := $(shell ruby -rrbconfig -e 'print RbConfig::CONFIG["sitearchdir"]')

ADDITIONAL_INCLUDE_DIRS = -I$(RUBY_ARCH_DIR)
ADDITIONAL_OBJCFLAGS = -Wall -g -DVERSION=\"$(VERSION)\"

$(LIBRARY_NAME)_OBJC_FILES = $(wildcard *.m)
LIBRARIES_DEPEND_UPON  =  $(FND_LIBS) $(GUI_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS) $(CONFIG_SYSTEM_LIBS)


include $(GNUSTEP_MAKEFILES)/library.make

include GNUmakefile.postamble
