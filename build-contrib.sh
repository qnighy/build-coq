#!/bin/sh -v

. ./config.sh

NAME=$1

export PATH=${OCAML_ROOT}/bin:$PATH
export PATH=`cygpath -u ${COQ_ROOT}`/bin:$PATH

tar xf contrib-${COQ_VERSION}/${NAME}.tar.gz -C contrib-${COQ_VERSION}
cd contrib-${COQ_VERSION}/${NAME}

coq_makefile -f Make -o Makefile && \
make -j${PARALLEL_BUILD} && \
make install
