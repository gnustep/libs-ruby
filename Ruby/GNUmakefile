#
#  Makefile for Ruby Interface to GNUstep - Ruby part
#
# $Id$
#
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Written by: Laurent Julliard (<laurent@julliard-online.org>)
#
#  This file is part of the GNUstep Java Interface Library.
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

# Dynamically determine where the things must be installed
# in Ruby
RUBY_SITE_LIB_DIR := $(shell ruby -rrbconfig -e 'print Config::CONFIG["sitelibdir"]')


after-install::
	@cp -f rigs.rb Foundation.rb AppKit.rb $(RUBY_SITE_LIB_DIR)
	@rm -rf $(RUBY_SITE_LIB_DIR)/rigs/*
	@cp -rf rigs $(RUBY_SITE_LIB_DIR)

# Is there something more appropriate than tool.make here ?
include $(GNUSTEP_MAKEFILES)/tool.make