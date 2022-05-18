#!/bin/sh
##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2014 Uwe Hermann <uwe@hermann-uwe.de>
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

# Uncomment/set the following to match your cross-toolchain setup.
# TOOLCHAIN=...
# TOOLCHAIN_TRIPLET=...
# C="--host=$TOOLCHAIN_TRIPLET"
# export PATH=$TOOLCHAIN/bin:$PATH

# The path where the compiled packages will be installed.
PREFIX=/workspace/build/linux/


# The path where the libsigrok Python bindings will be installed.
PYPATH=$PREFIX/lib/python2.7/site-packages

SOURCEPATH=/workspace

# JDK include path. Usually found automatically, except on FreeBSD.
if [ `uname` = "FreeBSD" ]; then
	JDK="--with-jni-include-path=/usr/local/openjdk7/include"
fi

# Edit this to control verbose build output.
# V="V=1 VERBOSE=1"

# Edit this to enable/disable/modify parallel compiles.
PARALLEL="-j 4"

# Edit this to enable/disable building certain components.
BUILD_SIGROK_FIRMWARE_FX2LAFW=0
BUILD_SIGROK_CLI=0

# Uncomment the following lines to build with clang and run scan-build.
# export CC=clang
# export CXX=clang++
# SB="scan-build -k -v"

# You usually don't need to change anything below this line.

# -----------------------------------------------------------------------------

P="$PREFIX/lib/pkgconfig"
C="$C --prefix=$PREFIX"

# libserialport
cd $SOURCEPATH/libserialport
./autogen.sh
mkdir -p build
cd build
$SB ../configure $C
$SB make $PARALLEL $V
make install $V

# libsigrok
mkdir -p $PYPATH
cd $SOURCEPATH/libsigrok
./autogen.sh
mkdir -p build
cd build
PKG_CONFIG_PATH=$P $SB ../configure --without-libbluez --enable-all-drivers=false --enable-embedded-logic-analyzer --enable-demo $C $JDK
$SB make $PARALLEL $V
PYTHONPATH=$PYPATH $SB make install $V
$SB make check $V

# libsigrokdecode
cd $SOURCEPATH/libsigrokdecode
./autogen.sh
mkdir -p build
cd build
PKG_CONFIG_PATH=$P $SB ../configure $C
$SB make $PARALLEL $V
make install $V
$SB make check $V

# PulseView
cd $SOURCEPATH/pulseview
mkdir -p build
cd build
PKG_CONFIG_PATH=$P $SB cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX -DDISABLE_WERROR=y -DENABLE_TESTS=y -DCMAKE_EXPORT_COMPILE_COMMANDS=y ..
$SB make $PARALLEL $V
make install $V
$SB make test $V

cd /workspace
