#!/usr/bin/perl
use strict;

use FindBin qw($Bin);

BEGIN {
	unshift @INC, $Bin . "/bin";
}

use arfflib;
use common;

my ($workDir, $sourceDir, $modelFilename) = processArgs();

# create a workdir
$workDir = common::initWorkDir($workDir);

my $labelmeFilename = $workDir . "/labelme.arff";
my $labelmeIdsFn = $workDir . "/labelme.ids";

# build freqvec files for the whole dir
my ($tuples, $set, $lp) = tuplesFromDir($sourceDir, $sourceDir);

# make links to hyp, ref and src files
common::linkFiles($sourceDir, $sourceDir, $tuples, $workDir);

# use the Makefile to build freqvec files
common::buildFiles($workDir, $tuples);

# create the unlabelled set file
createLabelmeFile($tuples, $set, $lp, $workDir . "/" . $common::auxFilesDir, $labelmeFilename, $labelmeIdsFn);

my $sysLevIndicator = ($common::doSegLev? "": "x");

# apply the classifier to predict on the created labelme file:
common::syscmd("java -Xmx5g -cp $common::wekaJar $common::wekaClassifier -T $labelmeFilename -l $modelFilename -classifications weka.classifiers.evaluation.output.prediction.CSV | cut -d , -f 3,5 | cut -d : -f 2 | grep -v '^\\s*\$' | tail -n +3 | paste -d , $labelmeIdsFn - | perl $Bin/bin/genfinscores.pl $sysLevIndicator");

print STDERR "done\n";

#####
#
#####
sub createLabelmeFile {
	print STDERR "Creating the labelme set file\n";
	
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
				'hypisref' => undef,
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
			'hypisref' => 1,
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
sub processArgs {
	common::processOptions();
	
	if (@ARGV < 3) {
		print STDERR
"This script applies a previously trained model to rank
a set of hypothesis translations from a given directory

Usage: score.pl [options] work-dir file-source-dir trained-model-file

the work-dir can be a new, non-existent directory (which will be created),
but specify the same path to avoid re-generating the error analysis files
during repeated experiments

Options:
   -m sets the number of threads to use (default: 2)
   -s produces segment-level scores instead of system-level

";
		die;
	}
	
	return @ARGV;
}
