#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2013-2020 Uwe Hermann <uwe@hermann-uwe.de>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

set -e

# Build target: "i686" (32bit) or "x86_64" (64bit).
TARGET="x86_64"

# The path where your MXE directory is located.
MXE=/home/container/mxe

# The base path prefix where the cross-compiled packages will be installed.
PREFIXBASE=/workspace/build/windows/sr

# The base path prefix where to download files to and where to build packages.
BUILDBASE=/workspace/build/windows/build

SOURCEPATH=/workspace

# Edit this to control verbose build output.
# V="V=1 VERBOSE=1"

# Edit this to enable/disable/modify parallel compiles.
PARALLEL="-j 4"

# Edit this to enable/disable debug builds.
DEBUG=0

# Optionally show some progress as the script executes.
# ECHO=true
ECHO=echo

# You usually don't need to change anything below this line.

# -----------------------------------------------------------------------------

$ECHO "setting up fetch variables ..."

# Construct the build and install directory pathnames.
if [ $TARGET = "i686" ]; then
	SUFFIX="32"
else
	SUFFIX="64"
fi

PYTHON_FILES=/home/container/files/Python34_$SUFFIX

if [ $DEBUG = 1 ]; then
	# CFLAGS/CXXFLAGS contains "-g" per default for autotools projects.
	BUILD_TYPE="Debug"
	PREFIX=$PREFIXBASE"_debug_"$SUFFIX
	BUILDDIR=$BUILDBASE"_debug_"$SUFFIX
else
	BUILD_TYPE="Release"
	PREFIX=$PREFIXBASE"_release_"$SUFFIX
	BUILDDIR=$BUILDBASE"_release_"$SUFFIX
fi

# -----------------------------------------------------------------------------

$ECHO "setting up toolchain variables ..."

# We need to find tools in the toolchain.
export PATH=$MXE/usr/bin:$PATH

TOOLCHAIN_TRIPLET="$TARGET-w64-mingw32.static.posix"

CMAKE="$TOOLCHAIN_TRIPLET-cmake"

P="$PREFIX/lib/pkgconfig"
P2="$MXE/usr/$TOOLCHAIN_TRIPLET/lib/pkgconfig"
C="--host=$TOOLCHAIN_TRIPLET --prefix=$PREFIX CPPFLAGS=-D__printf__=__gnu_printf__"
L="--disable-shared --enable-static"

if [ $TARGET = "i686" ]; then
	export PKG_CONFIG_PATH_i686_w64_mingw32_static_posix="$P:$P2"
else
	export PKG_CONFIG_PATH_x86_64_w64_mingw32_static_posix="$P:$P2"
fi

# libsigrok
$ECHO "component libsigrok ..."
cd $SOURCEPATH/libsigrok
make $PARALLEL $V
make install $V

# # PulseView
$ECHO "component pulseview ..."
cd $SOURCEPATH/pulseview
make $PARALLEL $V
# make manual
if [ $DEBUG = 1 ]; then
	make install $V
else
	make install/strip $V
fi

$ECHO "cross compile script done."

mv $PREFIX/bin/pulseview.exe $PREFIX/out/

cd /workspace
