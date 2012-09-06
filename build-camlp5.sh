#!/bin/sh -v

. ./config.sh

export PATH=${OCAML_ROOT}/bin:$PATH

tar xf camlp5-${CAMLP5_VERSION}.tgz
cd camlp5-${CAMLP5_VERSION}
./configure --strict
make -j${PARALLEL_BUILD} world.opt && make install
cp lib/gramlib.a ${OCAML_ROOT}/lib/camlp5
cd ..
