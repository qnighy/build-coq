#!/bin/sh -v

. ./config.sh

export PATH=${OCAML_ROOT}/bin:$PATH
export PATH=${GTK_ROOT}/bin:$PATH
# export CYGWIN=nobinmode

tar xf lablgtk-${LABLGTK_VERSION}.tar.gz
cd lablgtk-${LABLGTK_VERSION}
# ./configure --prefix=${GTK_ROOT} --disable-gtktest
./configure --disable-gtktest
make -j${PARALLEL_BUILD} && \
make -j${PARALLEL_BUILD} opt && \
make install
cp -r ${OCAML_ROOT}/lib/site-lib/lablgtk2 ${OCAML_ROOT}/lib
cd ..

