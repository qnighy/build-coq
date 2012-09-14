#!/bin/sh -v

. ./config.sh

mkdir -p logs

# for i in `cd contrib-${COQ_VERSION}; echo *.tar.gz | sed -e 's/[.]tar[.]gz//g'`
for i in $@
do
  echo "building $i ..."
  time ./build-contrib.sh $i >logs/$i.log 2>&1
  result=$?
  echo "result:            $result"
  if [ $result -ne 0 ]; then
    exit $result
  fi
done

