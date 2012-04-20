#!/bin/bash

bindir=$( dirname $0 )/bin

while getopts ":s" opt; do
	case $opt in
		s)
			seglev=1
			shift
			;;
		\?)
			echo "Invalid option -$OPTARG" >& 2
			;;
	esac
done

manranks=$1
autoranks=$2

if [[ -z $manranks || -z $autoranks ]]
then
	echo "Usage: evalsys.sh [-s] man-ranks auto-sys-metrics" >&2
	exit 1
fi

if [[ ! -e $manranks ]]
then
	echo "The manual ranking file \`$manranks' does not exist"
	exit 1
fi

if [[ ! -e $autoranks ]]
then
	echo "The automatic score file \`$autoranks' does not exist"
	exit 1
fi

if [ -z $seglev ]
then
	echo "System-level rank correlation:"
	cat $manranks \
		| $bindir/manseg2sys.pl \
		| grep -v _ref \
		| cat - $autoranks \
		| perl $bindir/generate-table.perl \
		| grep -v "n/a" \
		| python $bindir/spearmans-rank.py
else
	echo "Segment-level rank correlation:"
	echo "(todo)"
fi
