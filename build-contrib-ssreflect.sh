#!/bin/sh -v

. ./config.sh

export PATH=${OCAML_ROOT}/bin:$PATH
export PATH=`cygpath -u ${COQ_ROOT}`/bin:$PATH
export COQTOP=${COQ_ROOT}
export COQLIB=${COQ_ROOT}
export COQBIN=${COQ_ROOT}/bin/

tar xf ssreflect-${SSR_VERSION}.tar.gz
cd ssreflect-${SSR_VERSION}
cp Make Make.dynamic
sed -e '/<static>/,/<\/static>/s/#//;/<dynamic>/,/<\/dynamic>/s/^/#/' Make.dynamic > Make.static
cp Make.static Make
make -j${PARALLEL_BUILD} && \
make install
cp src/ssreflect.cmx ${COQ_ROOT}/lib/user-contrib/Ssreflect/
cp src/ssreflect.o   ${COQ_ROOT}/lib/user-contrib/Ssreflect/
cd ..

${COQ_ROOT}/bin/coqmktop.exe -ide -opt ${COQ_ROOT}/lib/user-contrib/Ssreflect/ssreflect.cmx -o ${COQ_ROOT}/bin/coqide.opt.exe
${COQ_ROOT}/bin/coqmktop.exe -top -opt ${COQ_ROOT}/lib/user-contrib/Ssreflect/ssreflect.cmx -o ${COQ_ROOT}/bin/coqtop.opt.exe
${COQ_ROOT}/bin/coqmktop.exe -ide ${COQ_ROOT}/lib/user-contrib/Ssreflect/ssreflect.cmo -o ${COQ_ROOT}/bin/coqide.byte.exe
${COQ_ROOT}/bin/coqmktop.exe -top ${COQ_ROOT}/lib/user-contrib/Ssreflect/ssreflect.cmo -o ${COQ_ROOT}/bin/coqtop.byte.exe
rm ${COQ_ROOT}/bin/coqide.exe
rm ${COQ_ROOT}/bin/coqtop.exe
rm ${COQ_ROOT}/bin/coqchk.exe
cp ${COQ_ROOT}/bin/coqide.opt.exe ${COQ_ROOT}/bin/coqide.exe
cp ${COQ_ROOT}/bin/coqtop.opt.exe ${COQ_ROOT}/bin/coqtop.exe
cp ${COQ_ROOT}/bin/coqchk.opt.exe ${COQ_ROOT}/bin/coqchk.exe
