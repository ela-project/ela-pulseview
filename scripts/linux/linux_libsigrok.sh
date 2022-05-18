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

# libsigrok
cd $SOURCEPATH/libsigrok/build
$SB make $PARALLEL $V
PYTHONPATH=$PYPATH $SB make install $V
$SB make check $V

# cd $SOURCEPATH/pulseview/build
# $SB make $PARALLEL $V
# make install $V
# $SB make test $V

cd /workspace
