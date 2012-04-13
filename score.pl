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

my $labelmeFilename = $tempDir . "/labelme.arff";
my $labelmeIdsFn = $tempDir . "/labelme.ids";

unless (-e $labelmeFilename) {
	# build freqvec files for the whole dir
	my ($tuples, $set, $lp) = tuplesFromDir($hypSourceDir, $refSourceDir);

	# make links to hyp, ref and src files
	common::linkFiles($hypSourceDir, $refSourceDir, $tuples, $tempDir);

	# use the Makefile to build freqvec files
	common::buildFiles($tempDir, $tuples);
	
	# create the unlabelled set file
	createLabelmeFile($tuples, $set, $lp, $tempDir . "/" . $common::auxFilesDir, $labelmeFilename, $labelmeIdsFn);
}

# apply the classifier to predict on the created labelme file:
common::syscmd("java -Xmx5g -cp $common::wekaJar $common::wekaClassifier -T $labelmeFilename -l $modelFilename -classifications weka.classifiers.evaluation.output.prediction.CSV | cut -d , -f 3,5 | cut -d : -f 2 | grep -v '^\\s*\$' | tail -n +3 | paste -d , $labelmeIdsFn - | perl $Bin/bin/genfinscores.pl");

#####
#
#####
sub createLabelmeFile {
	my ($tuples, $set, $lp, $srcDir, $labelmeFeatFn, $labelmeIdsFn) = @_;
	
	my $data = [];

	while (my ($hKey, $hInfo) = each(%$tuples)) {
		my $file = "$srcDir/$hKey.$common::vecSuffix";
		
		readfile($file, $data, $hInfo->{'sysId'});
	}
	
	open(my $idfh, ">$labelmeIdsFn") or die ("Failed to open `$labelmeIdsFn' for reading");
	open(my $featfh, ">$labelmeFeatFn") or die ("Failed to open `$labelmeFeatFn' for reading");

	for my $lineNr (0..$#$data) {
		my @ids = sort keys %{$data->[$lineNr]};
		
		for my $i (1..$#ids) {
			for my $j (0..($i - 1)) {
				submitPair($idfh, $featfh, $set, $lp, \@ids, $i, $j, $data, $lineNr);
			}
		}
	}

	close($idfh);
	close($featfh);
}

#####
#
#####
sub submitPair {
	my ($idfh, $featfh, $genSet, $genLp, $ids, $i, $j, $data, $lineNr) = @_;
	
	print $idfh "$genSet,$genLp,$lineNr," .
		$ids->[$i] . "," . $ids->[$j] . "\n";
	
	arfflib::display($featfh, $data->[$lineNr]->{$ids->[$i]},
		$data->[$lineNr]->{$ids->[$j]}, '?', "insert-info-here", undef);
}

#####
#
#####
sub readfile {
	my ($filename, $data, $id) = @_;
	
	open(FH, $filename) or die ("Failed to open `$filename' for reading");
	
	my $lineNr = 0;
	
	while (<FH>) {
		s/[\n\r]//g;
		$data->[$lineNr++]->{$id} = [split(/,/)];
	}
	
	close(FH);
}

#####
#
#####
sub tuplesFromDir {
	my ($hypDir, $refDir) = @_;
	
	opendir(DH, $hypDir) or die("Failed to read dir `$hypDir'");
	
	my ($genSet, $genLp) = (undef, undef);
	
	my %hypFiles =
		map {
			s/\Q$common::sourceFileSuffix\E$//g;
			
			my ($set, $lp, $sysId) = split(/\./);
			my ($srcLang, $tgtLang) = split(/-/, $lp);
			
			if (!defined($genSet) and !defined($genLp)) {
				$genSet = $set;
				$genLp = $lp;
			}
			elsif ($genSet ne $set) {
				die("It only makes sense to compare translations of the same test set into the same language; conflicting sets `$genSet' and `$set'");
			}
			elsif ($genLp ne $lp) {
				die("It only makes sense to compare translations of the same test set into the same language; conflicting language pairs `$genLp' and `$lp'");
			}
			
			$_ => {
				'srchyp' => $_,
				'ref' => "$set.$tgtLang",
				'src' => "$set.$srcLang",
				'set' => $set,
				'lp' => $lp,
				'sysId' => $sysId }
		}
		grep {
			/[^.]+(\.[^.]+){2}\Q$common::sourceFileSuffix\E$/
		}
		readdir(DH);
	
	closedir(DH);
	
	my ($srcLang, $tgtLang) = split(/-/, $genLp);
	
	$hypFiles{"$genSet.$genLp._ref"} = {
			'srchyp' => "$genSet.$tgtLang",
			'ref' => "$genSet.$tgtLang",
			'src' => "$genSet.$srcLang",
			'set' => $genSet,
			'lp' => $genLp,
			'sysId' => "_ref"
		};
	
	return (\%hypFiles, $genSet, $genLp);
}

#####
#
#####
sub processOptions {
	return @ARGV;
}
