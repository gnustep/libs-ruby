#
#  Main Makefile for GNUstep Ruby Interface Library.
#  
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Written by: Laurent Julliard <laurent@julliard-online.org>
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

PACKAGE_NAME = rigs
# Keep it in sync manually with Source/GNUmakefile
VERSION = 0.2.1

GNUSTEP_INSTALLATION_DIR=$(GNUSTEP_LOCAL_ROOT)
RPM_DISABLE_RELOCATABLE=YES

SUBPROJECTS = Source Ruby Testing

include $(GNUSTEP_MAKEFILES)/aggregate.make

