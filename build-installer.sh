#!/bin/sh -v

. ./config.sh

export PATH=${NSIS_ROOT}:$PATH

cp coq-${COQ_VERSION}/ide/coq.ico logo.ico
./build-installer.pl ${COQ_ROOT} ${COQ_VERSION} ${OCAML_ROOT} ${OCAML_VERSION} && \
makensis installer.nsi

