#!/bin/sh -v

. ./config.sh

NAME=$1

export PATH=`cygpath -u ${OCAML_ROOT}`/bin:$PATH
export PATH=`cygpath -u ${COQ_ROOT}`/bin:$PATH
export CC=i686-w64-mingw32-gcc
export COQTOP=${COQ_ROOT}
export COQLIB=${COQ_ROOT}/lib/
export COQBIN=${COQ_ROOT}/bin/

if ! tar xf contrib-${COQ_VERSION}/${NAME}.tar.gz -C contrib-${COQ_VERSION}; then
  exit 1
fi
cd contrib-${COQ_VERSION}/${NAME}

for i in `echo ../${NAME}-*.patch | sort`
do
  if [ -f $i ]
  then
    patch -p1 < $i
  fi
done

cat > coqtop-config.sh <<EOD
#!/bin/sh
${COQBIN}coqtop -config | dos2unix | tr '\\\\' /
EOD
chmod a+x coqtop-config.sh

case $NAME in
  BDDs)
    PARALLEL_BUILD=1
    ;;
  Exceptions)
    PARALLEL_BUILD=1
    ;;
  FingerTree)
    PARALLEL_BUILD=1
    ;;
esac

coq_makefile -f Make -o Makefile && cp Makefile Makefile.orig && \
sed -e 's/\r//g;s/$(COQBIN)coqtop -config/.\/coqtop-config.sh/g;s/user-contrib/user-contrib-postload/g' < Makefile.orig > Makefile && rm Makefile.orig && \
make -j${PARALLEL_BUILD} && \
make install
