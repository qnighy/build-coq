#!/bin/sh -v

. ./config.sh

export PATH=`cygpath -u ${OCAML_ROOT}/bin`:$PATH
export PATH=${GTK_ROOT}/bin:$PATH
export CC=i686-w64-mingw32-gcc

tar xf coq-${COQ_VERSION}.tar.gz
cd coq-${COQ_VERSION}

for i in `echo ../coq-${COQ_VERSION}-*.patch | sort`
do
  if [ -f $i ]
  then
    patch -p1 < $i
  fi
done

cp Makefile.build Makefile.build.tmp
./configure -prefix ${COQ_ROOT} -libdir ${COQ_ROOT}/lib -opt -coqide opt -with-doc no -with-geoproof no \
  -arch win32 -camldir ${OCAML_ROOT}/bin -usecamlp5 && \
make -j${PARALLEL_BUILD} world && \
make install

rm -r ${COQ_ROOT}/emacs
rm -r ${COQ_ROOT}/latex

rm ${COQ_ROOT}/bin/coqide.exe
rm ${COQ_ROOT}/bin/coqtop.exe
rm ${COQ_ROOT}/bin/coqchk.exe
cp ${COQ_ROOT}/bin/coqide.opt.exe ${COQ_ROOT}/bin/coqide.exe
cp ${COQ_ROOT}/bin/coqtop.opt.exe ${COQ_ROOT}/bin/coqtop.exe
cp ${COQ_ROOT}/bin/coqchk.opt.exe ${COQ_ROOT}/bin/coqchk.exe
