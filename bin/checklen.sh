#!/bin/bash

filea=$1
fileb=$2

lena=$( cat $filea | wc -l )
lenb=$( cat $fileb | wc -l )

if [[ $lena != $lenb ]]
then
	echo "File $filea has $lena lines, but file $fileb has $lenb lines"
	#rm -v $fileb
	exit 42
fi
