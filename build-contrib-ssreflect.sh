#!/bin/sh -v

. ./config.sh

export PATH=`cygpath -u ${OCAML_ROOT}`/bin:$PATH
export PATH=`cygpath -u ${COQ_ROOT}`/bin:$PATH
export CC=i686-w64-mingw32-gcc
export COQTOP=${COQ_ROOT}
export COQLIB=${COQ_ROOT}/lib/
export COQBIN=${COQ_ROOT}/bin/

tar xf ssreflect-${SSR_VERSION}-coq${COQ_VERSION}.tar.gz
cd ssreflect-${SSR_VERSION}

cat > coqtop-config.sh <<EOD
#!/bin/sh
${COQBIN}coqtop -config | dos2unix | tr '\\\\' /
EOD
chmod a+x coqtop-config.sh

coq_makefile -f Make -o Makefile && cp Makefile Makefile.orig && \
sed -e 's/\r//g;s/$(COQBIN)coqtop -config/.\/coqtop-config.sh/g;s/user-contrib/user-contrib-postload/g' < Makefile.orig > Makefile && rm Makefile.orig && \
make -j${PARALLEL_BUILD} && \
make install
