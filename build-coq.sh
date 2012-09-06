#!/bin/sh -v

. ./config.sh

export PATH=`cygpath -u ${OCAML_ROOT}/bin`:$PATH
export PATH=${GTK_ROOT}/bin:$PATH

tar xf coq-${COQ_VERSION}.tar.gz
cd coq-${COQ_VERSION}
case ${COQ_VERSION} in
  8.3pl4)
    ./configure -prefix ${COQ_ROOT} -libdir ${COQ_ROOT}/lib -opt -coqide opt -with-doc no -with-geoproof no \
      -with-cc `which i686-pc-mingw32-gcc` \
      -with-ar `which i686-pc-mingw32-ar` \
      -with-ranlib `which i686-pc-mingw32-ranlib` && \
    make -j${PARALLEL_BUILD} world && \
    make install

    rm -r ${COQ_ROOT}/emacs
    rm -r ${COQ_ROOT}/latex
    rm -r ${COQ_ROOT}/man

    rm ${COQ_ROOT}/bin/coqide.exe
    rm ${COQ_ROOT}/bin/coqide.opt.exe
    rm ${COQ_ROOT}/bin/coqide.byte.exe
    rm ${COQ_ROOT}/bin/coqtop.exe
    rm ${COQ_ROOT}/bin/coqtop.opt.exe
    rm ${COQ_ROOT}/bin/coqtop.byte.exe
    rm ${COQ_ROOT}/bin/coqchk.exe
    mv ${COQ_ROOT}/bin/coqchk.opt.exe ${COQ_ROOT}/bin/coqchk.exe
    ${COQ_ROOT}/bin/coqmktop.exe -ide -opt -o ${COQ_ROOT}/bin/coqide.exe
    ${COQ_ROOT}/bin/coqmktop.exe -top -opt -o ${COQ_ROOT}/bin/coqtop.exe
    ;;
  *)
    export CC=i686-pc-mingw32-gcc
    cp Makefile.build Makefile.build.tmp
    # sed -e 's/ln -sf/cp/g' Makefile.build.tmp > Makefile.build
    ./configure -prefix ${COQ_ROOT} -libdir ${COQ_ROOT}/lib -opt -coqide opt -with-doc no -with-geoproof no \
      -arch win32 -camldir ${OCAML_ROOT}/bin && \
    make -j${PARALLEL_BUILD} world && \
    make install

    rm -r ${COQ_ROOT}/emacs
    rm -r ${COQ_ROOT}/latex
    rm -r ${COQ_ROOT}/man

    rm ${COQ_ROOT}/bin/coqide.exe
    rm ${COQ_ROOT}/bin/coqide.opt.exe
    rm ${COQ_ROOT}/bin/coqide.byte.exe
    rm ${COQ_ROOT}/bin/coqtop.exe
    rm ${COQ_ROOT}/bin/coqtop.opt.exe
    rm ${COQ_ROOT}/bin/coqtop.byte.exe
    rm ${COQ_ROOT}/bin/coqchk.exe
    mv ${COQ_ROOT}/bin/coqchk.opt.exe ${COQ_ROOT}/bin/coqchk.exe
    ${COQ_ROOT}/bin/coqmktop.exe -ide -opt -o ${COQ_ROOT}/bin/coqide.exe
    ${COQ_ROOT}/bin/coqmktop.exe -top -opt -o ${COQ_ROOT}/bin/coqtop.exe
    ;;
esac

