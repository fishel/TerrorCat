#!/usr/bin/perl
use strict;
use warnings;

# This script calculates a Kendall's tau correlation score between WMT10 
# human relative rankings and automatic metric scores.  It counts discordant 
# and discordant pairs of human rankings and automatic metric scores and 
# derives a tau value by subtracting discordant from concordant pairs and 
# dividing by total number of pairs.  Pairs with a tie in the human 
# ranking are excluded, as are pairs that involve a no-rank judgment and 
# pairs that involve a judgment on the reference translation as a system.
# Usage:
# perl wmt10_segTau.pl <metric type> <segment-level language-pair specific 
# metric score file> <segment-level language-pair-specific human rank file>
# metric score file>
# Metric type must be either "acc" (accuracy) or "err" (error).  Only TERp 
# is an error-based metric in this distribution.
# Human rank file must be a language-pair-specific .csv file of the kind 
# included with this distribution for WMT10 human ranks.
# Metric score files must be formatted as those included with this 
# distribution, following MetricsMaTr10 segment-level score file format, with 
# all segment scores for one metric and one language pair in one file.  
# E.g.:
# perl wmt_segTau.pl acc Spanish-English-NIST-c-seg.scr 
# data_RNK_Spanish-English.csv
# The resulting tau value is written to standard output.

my @metrics = ( "TerrorCat" );
my @langPairs = ( "fr-en", "de-en", "es-en", "cz-en", "en-fr", "en-de", "en-es", "en-cz");

my %metricScores;

open METRICSCORES, '<', $ARGV[0];

#<METRIC NAME>   <LANG-PAIR>   <TEST SET>   <SYSTEM>   <SEGMENT NUMBER>   <SEGMENT SCORE>
while (<METRICSCORES>) {
	(my $metric, my $langPair, my $testSet, my $sysID, my $segmentId, my $score) = split(/\t/, $_);
	$metricScores{$metric}{$langPair}{$testSet}{$segmentId}{$sysID} = $score;
}
close METRICSCORES;

my %ctConcordPairs;
my %ctDiscordPairs;

my $genTestSet;

open HUMANSCORES, '<', $ARGV[1];
while (<HUMANSCORES>) {
	#(my $srclang, my $trglang, my $srcIndex, my $documentId, my $segmentId, my $judgeId, my $system1Number, my $system1Id, my $system2Number, my $system2Id, my $system3Number, my $system3Id, my $system4Number, my $system4Id, my $system5Number, my $system5Id, my $system1rank, my $system2rank, my $system3rank, my $system4rank, my $system5rank) = split(/,/, $_);
	#(my $langPair, my $testSet) = split(/\./, $documentId);
	#$testSet = "newssyscombtest2011";
	my ($langPair, $testSet, $segmentId, $system1Id, $system1rank, $system2Id, $system2rank, $system3Id, $system3rank, $system4Id, $system4rank, $system5Id, $system5rank) = split(/,/);
	$genTestSet = $testSet;
	my @systems = ( $system1Id, $system2Id, $system3Id, $system4Id, $system5Id );
	my @humanScores = ( $system1rank, $system2rank, $system3rank, $system4rank, $system5rank );
	for (my $i=0; $i < @systems; $i++) {
		for (my $j = $i+1; $j < @systems; $j++) {
# don't include refs, human no-ranks (-1), human ties
			if ($systems[$i] ne "_ref" && $systems[$j] ne "_ref" && $humanScores[$i] != -1 && $humanScores[$j] != -1 && $humanScores[$i] != $humanScores[$j]) {
				my $sysA = $systems[$i];
				my $sysB = $systems[$j];
				my $humanScoreB = $humanScores[$j];
				my $humanScoreA = $humanScores[$i];
				foreach my $metric (@metrics) {
				    if(exists $metricScores{$metric}{$langPair}{$testSet}{$segmentId}{$sysA} &&
				       exists $metricScores{$metric}{$langPair}{$testSet}{$segmentId}{$sysB}) {
					my $metricScoreA = $metricScores{$metric}{$langPair}{$testSet}{$segmentId}{$sysA};
					my $metricScoreB = $metricScores{$metric}{$langPair}{$testSet}{$segmentId}{$sysB};

					    # accuracy metrics (better translation = lower human ranking value, higher 
					    # automatic metric score)
					    if ($humanScoreA > $humanScoreB && $metricScoreA < $metricScoreB) {
						$ctConcordPairs{$metric}{$langPair}{$testSet}++;
					    } elsif ($humanScoreA < $humanScoreB && $metricScoreA > $metricScoreB) {
						$ctConcordPairs{$metric}{$langPair}{$testSet}++;
					    } else {
						$ctDiscordPairs{$metric}{$langPair}{$testSet}++;
					    }
				    }
				}
			}
		}
	}
}
close HUMANSCORES;

foreach my $langPair (@langPairs) {
	print "\t$langPair";
}
print "\n";

foreach my $metric (@metrics) {
	print $metric;
	foreach my $langPair (@langPairs) {
	    # tau calculation
	    if(exists $ctConcordPairs{$metric}{$langPair}{$genTestSet} &&
	       exists $ctDiscordPairs{$metric}{$langPair}{$genTestSet}) {
		my $numPairs =  $ctConcordPairs{$metric}{$langPair}{$genTestSet} + $ctDiscordPairs{$metric}{$langPair}{$genTestSet};
		my $tau = ($ctConcordPairs{$metric}{$langPair}{$genTestSet} - $ctDiscordPairs{$metric}{$langPair}{$genTestSet}) / $numPairs;
		if($tau =~ /\d\.\d\d\d/) {
		    $tau =~ m/(\d\.\d\d)(\d)/;
		    $tau = $1;
		    my $roundingDigit = $2;
		    if($roundingDigit >= 5) {
			$tau += 0.001;
		    }
		}
		print "\t$tau ($numPairs)";
	    } else {
		print "\t n/a";
	    }
	}
	print "\n";
}

