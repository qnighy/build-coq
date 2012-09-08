#!/bin/sh -v

. ./config.sh

# this actually not build the gtk

rm -rf ${GTK_ROOT}
unzip -d ${GTK_ROOT} gtk+-bundle_${GTK_VERSION}-*_win32.zip
find ${GTK_ROOT} -type f -name '*.exe' -exec 'chmod' 'a+x' '{}' ';'
find ${GTK_ROOT} -type d -exec 'chmod' 'a+x' '{}' ';'
find ${GTK_ROOT} -exec 'chown' 'qnighy.qnighy' '{}' ';'

