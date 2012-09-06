#!/bin/sh -v

. ./config.sh

./build-ocaml.sh && \
./build-camlp5.sh && \
./build-findlib.sh && \
./build-gtk.sh && \
./build-lablgtk.sh && \
./build-coq.sh
