package common;
use strict;

use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use Cwd;
use Getopt::Long;

our $addicterPath = "/home/mphi/proj/addicter";
our $hjersonPath = "/home/mphi/proj/hjerson";
our $wekaJar = "/home/mphi/proj/weka/weka.jar";

our $wekaClassifier = "weka.classifiers.functions.SMO";
our $sourceFileSuffix = ".fact";
our $threads = 2;
our $wekaMoreArgs = "-C 3";
our $doSegLev = undef;

our $vecSuffix = "freqvec";
our $auxFilesDir = "auxfiles";

sub processOptions {
	GetOptions(
		'm=i' => \$threads,
		's' => \$doSegLev,
		) or die("Option reading failed");
}

#####
#
#####
sub initTempDir {
	my ($tmpDir) = @_;
	
	unless (defined($tmpDir)) {
		$tmpDir = tempdir("terrorcat-XXXXX");
	}
	
	unless (-e $tmpDir) {
		mkdir($tmpDir);
	}
	
	unless (-e "$tmpDir/$auxFilesDir") {
		mkdir("$tmpDir/$auxFilesDir");
	}
	
	return $tmpDir;
}

#####
#
#####
sub buildFiles {
	my ($tempDir, $tuples) = @_;
	
	my $vecFileList = join(" ", map { "$tempDir/$auxFilesDir/$_.$vecSuffix" } keys %$tuples);
	
	syscmd("make -j$threads -f $Bin/bin/Makefile HOME=$Bin ADDICTER_PATH=$addicterPath HJERSON_PATH=$hjersonPath $vecFileList >&2");
}

#####
#
#####
sub linkFiles {
	my ($hypSrcDir, $refSrcDir, $tupleSet, $tmpDir) = @_;
	
	while (my ($hypName, $refSrcHash) = each(%$tupleSet)) {
		my ($actHypSrcDir, $actHypId) = ($refSrcHash->{'hypisref'})?
			($refSrcDir, $refSrcHash->{'ref'}):
			($hypSrcDir, $hypName);
		maybelink($actHypSrcDir, $actHypId, $tmpDir, $hypName . ".hfact");
		maybelink($refSrcDir, $refSrcHash->{'ref'}, $tmpDir, $hypName . ".rfact");
		maybelink($refSrcDir, $refSrcHash->{'src'}, $tmpDir, $hypName . ".sfact");
	}
}

#####
#
#####
sub maybelink {
	my ($srcDir, $srcFile, $tgtDir, $tgtName) = @_;
	
	my $oldFile = $srcDir . "/" . $srcFile . $sourceFileSuffix;
	my $newFile = $tgtDir . "/" . $auxFilesDir . "/" . $tgtName;
	
	unless ($oldFile =~ /^[\/~]/) {
		$oldFile = Cwd::cwd() . "/" . $oldFile;
	}
	
	unless (-e $oldFile) {
		die("Failed to link `$newFile' to `$oldFile', file does not exist");
	}
	
	unless (-l $newFile) {
		symlink($oldFile, $newFile);
		print STDERR "linked $newFile --> $oldFile;\n";
	}
}

#####
#
#####
sub syscmd {
	my ($cmd) = @_;
	print STDERR "\nRunning $cmd:\n";
	my $retStat = system($cmd);
	
	if ($retStat) {
		die("Command returned a status of $retStat");
	}
}

1;
