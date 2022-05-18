#!/bin/sh

SOURCEPATH=/workspace
COLOR='\033[0;32m'
NC='\033[0m'

echo "${COLOR}----libserialport${NC}"
cd $SOURCEPATH/libserialport
git clean -fdX

echo "${COLOR}----libsigrok${NC}"
cd $SOURCEPATH/libsigrok
git clean -fdX

echo "${COLOR}----libsigrokdecode${NC}"
cd $SOURCEPATH/libsigrokdecode
git clean -fdX

echo "${COLOR}----pulseview${NC}"
cd $SOURCEPATH/pulseview
git clean -fdX
git clean -fd
git reset --hard HEAD
