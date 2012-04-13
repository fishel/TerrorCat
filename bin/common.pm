package common;
use strict;

use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use Cwd;

<<<<<<< HEAD
our $vecSuffix = "freqvec";
our $auxFilesDir = "auxfiles";

our $sourceFileSuffix = ".fact";
=======
our $addicterPath = "/home/mphi/proj/addicter";
our $hjersonPath = "/home/mphi/proj/hjerson";
>>>>>>> 00047bd... minor changes
our $wekaJar = "/home/mphi/proj/weka/weka.jar";

our $wekaClassifier = "weka.classifiers.functions.SMO";
our $sourceFileSuffix = ".fact";
our $threads = 8;
our $wekaMoreArgs = "-C 3";
our $doSysLev = 1;

our $vecSuffix = "freqvec";
our $auxFilesDir = "auxfiles";

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
	
<<<<<<< HEAD
	my $currDir = Cwd::cwd();
	
	my $vecFileList = join(" ", map { "$tempDir/$auxFilesDir/$_.$vecSuffix" } keys %$tuples);
	
	chdir($Bin);
	
	syscmd("make -j$threads -f bin/Makefile $vecFileList >&2");
	
	chdir($currDir);
=======
	#my $currDir = Cwd::cwd();
	
	my $vecFileList = join(" ", map { "$tempDir/$auxFilesDir/$_.$vecSuffix" } keys %$tuples);
	
	#chdir($Bin);
	
	#print STDERR "now in " . Cwd::cwd() . ";\n";
	
	syscmd("make -j$threads -f $Bin/bin/Makefile HOME=$Bin ADDICTER_PATH=$addicterPath HJERSON_PATH=$hjersonPath $vecFileList >&2");
	
	#chdir($currDir);
>>>>>>> 00047bd... minor changes
}

#####
#
#####
sub linkFiles {
	my ($hypSrcDir, $refSrcDir, $tupleSet, $tmpDir) = @_;
	
	while (my ($hypName, $refSrcHash) = each(%$tupleSet)) {
<<<<<<< HEAD
		maybelink($hypSrcDir, $refSrcHash->{'srchyp'}, $tmpDir, $hypName . ".hfact");
=======
		my ($actHypSrcDir, $actHypId) = ($refSrcHash->{'hypisref'})?
			($refSrcDir, $refSrcHash->{'ref'}):
			($hypSrcDir, $hypName);
		maybelink($actHypSrcDir, $actHypId, $tmpDir, $hypName . ".hfact");
>>>>>>> 00047bd... minor changes
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
<<<<<<< HEAD
		die("Failed to link to `$oldFile', file does not exist");
=======
		die("Failed to link `$newFile' to `$oldFile', file does not exist");
>>>>>>> 00047bd... minor changes
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
<<<<<<< HEAD
	system($cmd);
=======
	my $retStat = system($cmd);
	
	if ($retStat) {
		die("Command returned a status of $retStat");
	}
>>>>>>> 00047bd... minor changes
}

1;
