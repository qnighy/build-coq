#!/bin/sh -v

. ./config.sh

export PATH=${OCAML_ROOT}/bin:$PATH

tar xf findlib-${FINDLIB_VERSION}.tar.gz
cd findlib-${FINDLIB_VERSION}
./configure -system mingw && make -j${PARALLEL_BUILD} && make install
cd ..
