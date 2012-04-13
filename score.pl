#!/usr/bin/perl
use strict;

use FindBin qw($Bin);

BEGIN {
	unshift @INC, $Bin . "/bin";
}

use arfflib;
use common;

my ($hypSourceDir, $refSourceDir, $modelFilename, $tempDir) = processOptions();

# create a workdir
$tempDir = common::initTempDir($tempDir);

my $labelmeFile = $tempDir . "/labelme.arff";

unless (-e $labelmeFile) {
	# build freqvec files for the whole dir
	$tuples = TODO!;

	# make links to hyp, ref and src files
	common::linkFiles($hypSourceDir, $refSourceDir, $tuples, $tempDir);

	# use the Makefile to build freqvec files
	common::buildFiles($tempDir, $tuples);
	
	# create the unlabelled set file
	createLabelmeFile(...);
}

# training:
#common::syscmd("java -Xmx5g -cp $common::wekaJar $common::wekaClassifier -v -M $common::wekaMoreArgs -t $trainingFilename -d $modelFilename");

common::syscmd("java "...);

#####
#
#####
sub processOptions {
	return @ARGV;
}
