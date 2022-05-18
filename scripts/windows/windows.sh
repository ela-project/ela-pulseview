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

# -----------------------------------------------------------------------------

mkdir -p $PREFIX
cd $PREFIX

$ECHO "preparing Python dependency ..."

# Cross-compiling Python is highly non-trivial, so we avoid it for now.
# The download below is a repackaged tarball of the official Python 3.4.4 MSI
# installer for Windows:
#   - https://www.python.org/ftp/python/3.4.4/python-3.4.4.msi
#   - https://www.python.org/ftp/python/3.4.4/python-3.4.4.amd64.msi
# The MSI file has been installed on a Windows box and then c:\Python34\libs
# and c:\Python34\include have been stored in the Python34_*.tar.gz tarball.
cp $PYTHON_FILES/Python34.tar.gz $PREFIX/Python34.tar.gz
tar xzf $PREFIX/Python34.tar.gz -C $PREFIX

# Fix for bug #1195.
if [ $TARGET = "x86_64" ]; then
	patch -N -p1 $PREFIX/Python34/include/pyconfig.h < /workspace/scripts/windows/pyconfig.patch
fi

# Create a dummy python3.pc file so that pkg-config finds Python 3.
mkdir -p $PREFIX/lib/pkgconfig
cat >$PREFIX/lib/pkgconfig/python3.pc <<EOF 
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include
Name: Python
Description: Python library
Version: 3.4
Libs: $PREFIX/Python34/libs/libpython34.a
Cflags: -I$PREFIX/Python34/include
EOF

# The python34.dll and python34.zip files will be shipped in the NSIS
# Windows installers (required for protocol decoding to work).
# The file python34.dll (NOT the same as python3.dll) is copied from an
# installed Python 3.4.4 (see above) from c:\Windows\system32\python34.dll.
# The file python34.zip contains all files from the 'DLLs', 'Lib', and 'libs'
# subdirectories from an installed Python on Windows (c:\python34), i.e. some
# libraries and all Python stdlib modules.
cp $PYTHON_FILES/python34.dll $PREFIX/python34.dll
cp $PYTHON_FILES/python34.zip $PREFIX/python34.zip

# In order to link against Python we need libpython34.a.
# The upstream Python 32bit installer ships this, the x86_64 installer
# doesn't. Thus, we generate the file manually here.
if [ $TARGET = "x86_64" ]; then
	# cp $PREFIX/python34.dll .
	$MXE/usr/$TARGET-w64-mingw32.static.posix/bin/gendef python34.dll
	$MXE/usr/bin/$TARGET-w64-mingw32.static.posix-dlltool \
		--dllname python34.dll --def python34.def \
		--output-lib libpython34.a
	mv -f libpython34.a $PREFIX/Python34/libs
fi

# We need to include the *.pyd files from python34.zip into the installers,
# otherwise importing certain modules (e.g. ctypes) won't work (bug #1409).
unzip -q $PREFIX/python34.zip *.pyd -d $PREFIX

# Zadig (we ship this with frontends for easy driver switching).
$ECHO "fetching zadig ..."
cp /home/container/files/zadig.exe $PREFIX/zadig.exe
cp /home/container/files/zadig_xp.exe $PREFIX/zadig_xp.exe

# libserialport
$ECHO "component libserialport ..."
cd $SOURCEPATH/libserialport
./autogen.sh
./configure $C $L
make $PARALLEL $V
make install $V

# libsigrok
$ECHO "component libsigrok ..."
cd $SOURCEPATH/libsigrok
./autogen.sh
./configure --without-libbluez --enable-all-drivers=false --enable-embedded-logic-analyzer --enable-demo $C $L
make $PARALLEL $V
make install $V

# libsigrokdecode
$ECHO "component libsigrokdecode ..."
cd $SOURCEPATH/libsigrokdecode
./autogen.sh
./configure $C $L
make $PARALLEL $V
make install $V

# # PulseView
$ECHO "component pulseview ..."
cd $SOURCEPATH/pulseview
patch -N -p1 < /workspace/scripts/windows/pulseview-manual-pdf-hack.patch
cp /workspace/scripts/windows/FileAssociation.nsh contrib
$CMAKE \
	-DCMAKE_INSTALL_PREFIX:PATH=$PREFIX \
	-DCMAKE_BUILD_TYPE=$BUILD_TYPE \
	-DDISABLE_WERROR=y \
	-DENABLE_TESTS=y \
	.
make $PARALLEL $V
# make manual
if [ $DEBUG = 1 ]; then
	make install $V
else
	make install/strip $V
fi

$ECHO "cross compile script done."

mkdir -p $PREFIX/out $PREFIX/out/share
mv $PREFIX/python34.zip $PREFIX/python34.dll $PREFIX/bin/pulseview.exe $PREFIX/zadig_xp.exe $PREFIX/zadig.exe $PREFIX/out/
mv $PREFIX/share/libsigrokdecode $PREFIX/out/share/libsigrokdecode

cd /workspace
