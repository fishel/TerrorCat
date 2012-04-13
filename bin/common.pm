package common;
use strict;

use File::Temp qw(tempfile tempdir);
use Cwd;

our $vecSuffix = "freqvec";
our $auxFilesDir = "auxfiles";

# TODO into conf file:
our $sourceFileSuffix = ".fact";
our $wekaJar = "/home/mphi/proj/weka/weka.jar";
our $wekaClassifier = "weka.classifiers.functions.SMO";
our $wekaMoreArgs = "-C 3";
our $threads = 8;

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
	syscmd("make -j$threads -f $Bin/bin/Makefile $vecFileList");
}

#####
#
#####
sub linkFiles {
	my ($hypSrcDir, $refSrcDir, $tupleSet, $tmpDir) = @_;
	
	while (my ($hypName, $refSrcHash) = each(%$tupleSet)) {
		maybelink($hypSrcDir, $hypName, $tmpDir, $hypName . ".hfact");
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
	
	unless (-l $newFile) {
		symlink($oldFile, $newFile);
		print "linked $newFile --> $oldFile;\n";
	}
}

#####
#
#####
sub syscmd {
	my ($cmd) = @_;
	print "\nRunning $cmd:\n";
	system($cmd);
}

1;
