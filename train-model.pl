#!/usr/bin/perl
use strict;

########################
# TODO: parameter processing, complaining about bad parameters, parametrize #threads, re-doing & others,
# usage message,...
########################

use FindBin qw($Bin);

BEGIN {
	unshift @INC, $Bin . "/bin";
}

use arfflib;
use common;

# handle cmdline options and arguments
my ($manRankFilename, $hypSourceDir, $refSourceDir, $modelFilename, $tempDir) = processOptions();

# create a workdir
$tempDir = common::initTempDir($tempDir);

my $trainingFilename = $tempDir . "/train.arff";

my $manRankData = readManRanks($manRankFilename);

# rebuild training file if necessary
unless (-e $trainingFilename) {
	# get list of hyp-ref-src tuples from manual ranking file
	my $tuples = getTuplesFromRankFile($manRankData);
	
	# make links to hyp, ref and src files
	common::linkFiles($hypSourceDir, $refSourceDir, $tuples, $tempDir);
	
	# use the Makefile to build freqvec files
	common::buildFiles($tempDir, $tuples);
	
	# build the training set file
	createTrainingFile($manRankData, $tempDir . "/" . $common::auxFilesDir, $trainingFilename);
}

# train a model on the newly created file
common::syscmd("java -Xmx5g -cp $common::wekaJar $common::wekaClassifier -v -M $common::wekaMoreArgs -t $trainingFilename -T $trainingFilename -d $modelFilename");

#####
#
#####
sub readManRanks {
	my ($fn) = @_;
	
	my $fh = getFh($fn);
	
	my @data = <$fh>;
	
	maybeclose($fh, $fn);
	
	return \@data;
}

#####
#
#####
sub createTrainingFile {
	my ($manRankData, $tmpAuxDir, $tgtFilename) = @_;
	
	my $stats = fillStats($manRankData, $tmpAuxDir);
	
	displayStats($stats, $tgtFilename);
}

#####
#
#####
sub displayStats {
	my ($stats, $filename) = @_;
	
	my $files = {};
	
	open(my $fh, ">$filename") or die("Failed to open `$filename' for writing");
	
	while (my ($path, $pHash) = each %$stats) {
		while (my ($lineNr, $lHash) = each %$pHash) {
			while (my ($id, $cmp) = each %$lHash) {
				my $firstBetter = $cmp->{1};
				my $secondBetter = $cmp->{-1};
				
				displayPair($fh, $files, $path, $lineNr, $id, $firstBetter <=> $secondBetter);
			}
		}
	}
	
	close($fh);
}

#####
#
#####
sub displayPair {
	my ($fh, $files, $path, $lineNr, $idPair, $cmp) = @_;
	
	if ($cmp == 0) {
		return;
	}
	
	my ($id1, $id2) = split(/\+/, $idPair);
	
	my $data1 = getData($files, $path, $id1, $lineNr);
	my $data2 = getData($files, $path, $id2, $lineNr);
	
	arfflib::display($fh, $data1, $data2, (($cmp > 0)? 'TRUE': 'FALSE'), "$id1/$id2, $path", 1);
}

#####
#
#####
sub getData {
	my ($fHash, $path, $id, $lineNr) = @_;
	
	my $fullPath = join(".", $path, $id, $common::vecSuffix);
	
	unless ($fHash->{$fullPath}) {
		$fHash->{$fullPath} = loadData($fullPath);
	}
	
	my $fData = $fHash->{$fullPath}->{'lines'};
	
	if (defined($fData)) {
		if ($#$fData < $lineNr - 1) {
			die("Line `$lineNr' not present in file `$fullPath' ($#$fData)");
		}
		
		return $fData->[$lineNr - 1];
	}
	else {
		return undef;
	}
}

#####
#
#####
sub loadData {
	my ($paramPath) = @_;
	
	my $path = $paramPath;
	
	if ($path =~ /^(.*)\/..-(..)\/([^.]+)\...-..\._ref\.$common::vecSuffix$/) {
		my ($prePath, $tgtLang, $set) = ($1, $2, $3);

		$path = "$prePath/src-ref/$set.$tgtLang.$common::vecSuffix";
	}
	
	unless (-e $path) {
		die("Path $path missing");
	}
	
	open(FH, $path) or die("Failed to open `$path' for reading");
	
	my $lineNr = 0;
	
	my @result = ();
	
	while (<FH>) {
		$lineNr++;
		s/[\n\r]//g;
		push @result, [split(/,/)];
	}
	
	close(FH);
	
	return { 'lines' => \@result };
}

#####
#
#####
sub fillStats {
	my ($manRankData, $srcDir) = @_;
	
	my $result = {};
	
	for (@$manRankData) {
		s/[\n\r]//g;
		
		my ($lp, $set, $lineNr, @rawRanks) = split(/,/);
		
		my @ranks = regrp(@rawRanks);
		
		my $thisPath = "$srcDir/$set.$lp";
		
		for my $rankIdx (0..$#ranks) {
			my $r1 = $ranks[$rankIdx];
			
			for my $otherIdx (0..($rankIdx - 1 )) {
				my $r2 = $ranks[$otherIdx];
				
				my @sortedPair = sort { $a->{'id'} cmp $b->{'id'} } ($r1, $r2);
				
				submitPair($result, $thisPath, $lineNr, @sortedPair);
			}
		}
	}
	
	return $result;
}

#####
#
#####
sub regrp {
	my @rawRanks = @_;
	
	my @result = ();
	
	while (my $id = shift @rawRanks) {
		my $rank = shift @rawRanks;
		
		push @result, { 'id' => $id, 'rank' => $rank };
	}
	
	return @result;
}

#####
#
#####
sub submitPair {
	my ($target, $path, $lineNr, $r1, $r2) = @_;
	
	my ($r1r, $r2r) = ($r1->{'rank'}, $r2->{'rank'});
	
	unless ($r1r == $r2r or $r1r == -1 or $r2r == -1) {
		#update stats with both 1+2 and 2+1 pairs;
		#1 for rank1 < rank2 (better) and -1 otherwise
		$target->{$path}->{$lineNr}->{$r1->{'id'} . "+" . $r2->{'id'}}->{$r2->{'rank'} <=> $r1->{'rank'}}++;
		
		#1 for rank2 < rank1 (better) and -1 otherwise
		$target->{$path}->{$lineNr}->{$r2->{'id'} . "+" . $r1->{'id'}}->{$r1->{'rank'} <=> $r2->{'rank'}}++;
	}
}

#####
#
#####
sub getTuplesFromRankFile {
	my ($data) = @_;
	
	my $result = {};
	
	for (@$data) {
		s/[\r\n]//g;
		
		my @fields = split(/,/);
		
		my ($langPair, $setId, $lineNr) = splice(@fields, 0, 3);
		
		my ($srcLang, $tgtLang) = split(/-/, $langPair);
		
		while (@fields > 0) {
			my ($sysId, $sysRank) = splice(@fields, 0, 2);
			
			my $hypName = "$setId.$langPair.$sysId";
			my $refName = "$setId.$tgtLang";
			my $srcName = "$setId.$srcLang";
			
			$result->{ $hypName } = {
<<<<<<< HEAD
				'srchyp' => (($sysId eq "_ref")? $refName: $hypName),
=======
				'hypisref' => ($sysId eq "_ref"),
>>>>>>> 00047bd... minor changes
				'ref' => $refName,
				'src' => $srcName};
		}
	}
	
	return $result;
}

#####
#
#####
sub getFh {
	my ($filename) = @_;
	
	my $fh;
	
	if ($filename eq "-") {
		$fh = *STDIN;
	}
	else {
		open($fh, $filename) or die ("Failed to open `$filename' for reading");
	}
	
	return $fh;
}

#####
#
#####
sub maybeclose {
	my ($fh, $fn) = @_;
	
	unless ($fn eq "-") {
		close($fh);
	}
}

#####
#
#####
sub processOptions {
	if (@ARGV < 4) {
		print STDERR "This script trains a model using a manual ranking file and\n" .
			"a set of hypothesis translations from a given directory\n" .
			"(and their corresponding source and reference files in another given directory)\n\n" .
			"Usage: train-model.pl man-rank-file hyp-dir ref-dir file-to-save-model-to [temp-dir]\n\n" .
			"specify the same temp-dir to avoid re-generating the error analysis files and such\n\n";
		die;
	}
	
	return @ARGV;
}
