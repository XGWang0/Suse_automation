#!/bin/bash

# creates ctags

ctags -R .
BASE=".."
for D in 1 2 3 4 5
do
	find -maxdepth $D -mindepth $D -type d | while read A
	do
		pushd "$A"
		ctags -R $BASE
		popd
	done
	BASE="$BASE/.."
done

