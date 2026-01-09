#!/bin/bash

if [ -z "$1" ]; then
  TEXTO="Que me gusta la bash!!!!"
else
  TEXTO="$1"
fi

mkdir -p foo/dummy
mkdir -p foo/empty

echo "$TEXTO" > foo/dummy/file1.txt
touch foo/dummy/file2.txt

cat foo/dummy/file1.txt > foo/dummy/file2.txt
mv foo/dummy/file2.txt foo/empty