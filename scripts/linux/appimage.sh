#!/bin/bash
##
## Copyright (C) 2016 Simon Peter
## Copyright (C) 2017-2018 Uwe Hermann <uwe@hermann-uwe.de>
## This file is licensed under the terms of the MIT license.
##

# Bundle PulseView/sigrok-cli (and deps) as an AppImage for x86_64/i386 Linux.
# Note: This assumes the full sigrok stack has been installed into $PREFIX.

PREFIX=/workspace/build/linux/

APPIMAGEKIT_OUTDIR=/home/container/appimage

# ARCH=i386
ARCH=x86_64

PYVER=3.7

########################################################################
# You usually don't have to change anything below this line
########################################################################

if [ "x$1" = "xsigrok-cli" ]; then
	APP=sigrok-cli
else
	APP=PulseView
fi
LOWERAPP=${APP,,} 

export ARCH
export STATIC_FILES=`pwd`/contrib

# Add $APPIMAGEKIT_OUTDIR so we can find all the binaries there.
export PATH=$APPIMAGEKIT_OUTDIR:$PATH

A="/workspace/build/appimage/$APP/$APP.AppDir"
mkdir -p $A/usr/bin $A/usr/lib $A/usr/share
cd /workspace/build/appimage/$APP

. $STATIC_FILES/functions.sh

########################################################################
# Get build products from $PREFIX
########################################################################

cd $APP.AppDir/

cp $PREFIX/bin/$LOWERAPP usr/bin/
chmod a+x usr/bin/*
cp $PREFIX/lib/lib*.so* usr/lib/
cp -r $PREFIX/share/libsigrokdecode usr/share/
# cp -r $PREFIX/share/sigrok-firmware usr/share/
mkdir -p usr/share/applications
cp $PREFIX/share/applications/org.sigrok.$APP.desktop usr/share/applications
cp -r $PREFIX/share/icons usr/share/
cp -r $PREFIX/share/metainfo usr/share/
cp -r $PREFIX/share/mime usr/share/

# Drop unneeded stuff.
if [ "x$1" = "xsigrok-cli" ]; then
	rm -f usr/lib/libsigc*
	rm -f usr/lib/libglibmm*
	rm -f usr/lib/libsigrokcxx*
	rm -f usr/share/icons/hicolor/*/apps/pulseview.*
	rm -f usr/share/metainfo/org.sigrok.PulseView.appdata.xml
else
	rm -f usr/share/icons/hicolor/scalable/apps/sigrok-cli.svg
fi

# Reduce binary size
strip usr/bin/*
strip usr/lib/*

########################################################################
# AppRun is the main launcher that gets executed when AppImage is run
########################################################################

cp $APPIMAGEKIT_OUTDIR/AppRun .

########################################################################
# Copy desktop and icon file to AppDir for AppRun to pick them up
########################################################################

cp $PREFIX/share/applications/org.sigrok.$APP.desktop .
cp $PREFIX/share/icons/hicolor/scalable/apps/$LOWERAPP.svg .

########################################################################
# Copy in the dependencies that cannot be assumed to be available
# on all target systems
########################################################################

copy_deps

if [ "x$1" != "xsigrok-cli" ]; then
	# Get all Qt5 plugins (won't be copied automatically).
	QT5PLUGINS=/usr/lib/$ARCH-linux-gnu/qt5/plugins # Host (+ AppRun) path.
	mkdir -p .$QT5PLUGINS
	cp -r $QT5PLUGINS/bearer .$QT5PLUGINS
	cp -r $QT5PLUGINS/egldeviceintegrations .$QT5PLUGINS
	cp -r $QT5PLUGINS/generic .$QT5PLUGINS
	cp -r $QT5PLUGINS/iconengines .$QT5PLUGINS
	cp -r $QT5PLUGINS/imageformats .$QT5PLUGINS
	cp -r $QT5PLUGINS/platforminputcontexts .$QT5PLUGINS
	cp -r $QT5PLUGINS/platforms .$QT5PLUGINS
	cp -r $QT5PLUGINS/printsupport .$QT5PLUGINS
	cp -r $QT5PLUGINS/xcbglintegrations .$QT5PLUGINS
	
	# Get some additional dependencies of the Qt5 plugins.
	ldd .$QT5PLUGINS/platforms/libqxcb.so | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v '{}' ./usr/lib || true
	ldd .$QT5PLUGINS/imageformats/libqsvg.so | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v '{}' ./usr/lib || true
fi

# Python 3
cp /usr/lib/$ARCH-linux-gnu/libpython$PYVER* ./usr/lib
mkdir -p ./usr/share/pyshared
cp -r /usr/lib/python$PYVER/* ./usr/share/pyshared # AppRun expects this path.

cp -r ./usr/share/pyshared/plat-$ARCH-linux-gnu/* ./usr/share/pyshared

########################################################################
# Delete stuff that should not go into the AppImage
########################################################################

move_lib
mv ./usr/lib/$ARCH-linux-gnu/* usr/lib/
rm -r ./usr/lib/$ARCH-linux-gnu/

delete_blacklisted

# Remove some incorrectly/unintentionally copied files.
rm -r ./home

########################################################################
# Determine the version of the app
########################################################################

VERSION="0.4.2-ela"
echo $VERSION

########################################################################
# Patch away absolute paths; it would be nice if they were relative
########################################################################

find usr/ -type f -executable -exec sed -i -e "s|/usr|././|g" {} \;

########################################################################
# AppDir complete
# Now packaging it as an AppImage
########################################################################

cd ..

VERSION=$VERSION $APPIMAGEKIT_OUTDIR/appimagetool --appimage-extract-and-run ./$APP.AppDir/
mkdir -p ../out/ || true
mv *.AppImage* ../out/
