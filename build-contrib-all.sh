#!/bin/sh -v

. ./config.sh

mkdir logs

for i in `cd contrib-${COQ_VERSION}; echo *.tar.gz | sed -e 's/[.]tar[.]gz//g'`
do
  echo "building $i ..."
  time ./build-contrib.sh $i 2>&1 | tee logs/$i.log
  echo "result:            $?"
done

