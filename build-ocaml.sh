#!/bin/sh -v

. ./config.sh

tar xf ocaml-${OCAML_VERSION}.tar.bz2
cd ocaml-${OCAML_VERSION}
cp config/m-nt.h config/m.h
cp config/s-nt.h config/s.h
sed -e 's/^PREFIX=.*/PREFIX='$(echo ${OCAML_ROOT}|sed -e 's/\//\\\//')'/;s/labltk//' config/Makefile.mingw > config/Makefile
make -f Makefile.nt world && \
make -f Makefile.nt bootstrap && \
make -f Makefile.nt opt && \
make -f Makefile.nt opt.opt && \
make -f Makefile.nt install
cd ..
