package common;
use strict;

use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use Cwd;
use Getopt::Long;

my $config = loadConfig("$Bin/config.ini");

our $addicterPath = $config->{'ADDICTER_PATH'};
our $hjersonPath = $config->{'HJERSON_PATH'};
our $wekaJar = $config->{'WEKA_JAR_PATH'};
our $threads = $config->{'DEFAULT_NUM_OF_THREADS'};

our $wekaClassifier = "weka.classifiers.functions.SMO";
our $sourceFileSuffix = ".fact";
our $wekaMoreArgs = "-C 3";
our $doSegLev = undef;

our $vecSuffix = "freqvec";
our $auxFilesDir = "auxfiles";

#####
#
#####
sub loadConfig {
	my ($path) = @_;
	
	my $result = {};
	
	open(FH, $path) or die ("Failed to open `$path' for reading");
	
	while (<FH>) {
		s/[\n\r]//g;
		
		my ($key, $val) = split(/=/, $_, 2);
		
		$result->{$key} = $val;
	}
	
	close(FH);
	
	return $result;
}

#####
#
#####
sub processOptions {
	GetOptions(
		'm=i' => \$threads,
		's' => \$doSegLev,
		) or die("Option reading failed");
}

#####
#
#####
sub initWorkDir {
	my ($workDir) = @_;
	
	unless (defined($workDir)) {
		$workDir = tempdir("terrorcat-XXXXX");
		print STDERR "work-dir is $workDir\n";
	}
	
	unless (-e $workDir) {
		mkdir($workDir);
	}
	
	unless (-e "$workDir/$auxFilesDir") {
		mkdir("$workDir/$auxFilesDir");
	}
	
	return $workDir;
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
