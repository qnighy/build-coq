#!/bin/sh -v

. ./config.sh

# this actually not build the gtk

rm -rf ${GTK_ROOT}
unzip -d ${GTK_ROOT} gtk+-bundle_${GTK_VERSION}-*_win32.zip

