#!/bin/sh -v

mv $1 $1.new
tar zxvf $1.tar.gz
diff -ru $1 $1.new > $1-1.patch
rm $1 $1.new -r
