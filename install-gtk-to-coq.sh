#!/bin/sh -v

. ./config.sh

 mkdir -p ${COQ_ROOT}/bin
 mkdir -p ${COQ_ROOT}/etc/gtk-2.0
 mkdir -p ${COQ_ROOT}/lib/gtk-2.0/2.10.0/engines
 mkdir -p ${COQ_ROOT}/share/themes/MS-Windows/gtk-2.0

 install -m 775 ${GTK_ROOT}/bin/libgdk-win32-2.0-0.dll            ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libcairo-2.dll                    ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libfontconfig-1.dll               ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libexpat-1.dll                    ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/freetype6.dll                     ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libpng14-14.dll                   ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgdk_pixbuf-2.0-0.dll           ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/intl.dll                          ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgio-2.0-0.dll                  ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libglib-2.0-0.dll                 ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgmodule-2.0-0.dll              ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgobject-2.0-0.dll              ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgthread-2.0-0.dll              ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libpango-1.0-0.dll                ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libpangocairo-1.0-0.dll           ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libpangoft2-1.0-0.dll             ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libpangowin32-1.0-0.dll           ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libgtk-win32-2.0-0.dll            ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/libatk-1.0-0.dll                  ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/bin/zlib1.dll                         ${COQ_ROOT}/bin
 install -m 775 ${GTK_ROOT}/share/themes/MS-Windows/gtk-2.0/gtkrc ${COQ_ROOT}/share/themes/MS-Windows/gtk-2.0
 touch ${COQ_ROOT}/etc/gtk-2.0/gtkrc
 echo 'gtk-theme-name = "MS-Windows"' >> ${COQ_ROOT}/etc/gtk-2.0/gtkrc

 install -m 775 ${GTK_ROOT}/lib/gtk-2.0/2.10.0/engines/libwimp.dll ${COQ_ROOT}/lib/gtk-2.0/2.10.0/engines
