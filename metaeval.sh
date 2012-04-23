#!/bin/bash

bindir=$( dirname $0 )/bin

manranks=$1
autoranks=$2

if [[ -z $manranks || -z $autoranks ]]
then
	cat >&2 <<HERE
This script calculates the correlation between manual and
automatic ranking; it uses Spearman's rho for document-level
evaluation and Kendall's tau for sentence-level evaluation

Usage: metaeval.sh man-ranks auto-sys-metrics

HERE
	
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

if [[ -z "$( head -1 $autoranks | cut -f 6 )" ]]
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
	$bindir/wmt11_segTau.pl $autoranks $manranks
fi
