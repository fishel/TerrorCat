#!/usr/bin/perl
use strict;

my $metricName = "TerrorCat";

my $sysLvl = defined($ARGV[0]);

my ($minVal, $maxVal) = (1e600, -1e600);

my %sysHash = ();

my $results = {};

my $nrOfLines = 0;

while (<STDIN>) {
	s/[\n\r]//g;
	my ($set, $lp, $lineNr, $betterSysId, $worseSysId, $outcome, $rawConfidence) = split(/,/);
	
	$nrOfLines = $lineNr + 1;
	
	$sysHash{$betterSysId} = 1;
	$sysHash{$worseSysId} = 1;
	
	if ($outcome eq 'FALSE') {
		($betterSysId, $worseSysId) = ($worseSysId, $betterSysId);
	}
	
	if ($sysLvl) {
		$lineNr = 0;
	}
	
	my $normConfidence = $rawConfidence - 0.5;
	#my $normConfidence = ($rawConfidence == 0.5)? 0: 1;
	
	$results->{$betterSysId}->{$set}->{$lp}->[$lineNr] += $normConfidence;
	$results->{$worseSysId}->{$set}->{$lp}->[$lineNr] -= $normConfidence;
	
	$maxVal = max($results->{$betterSysId}->{$set}->{$lp}->[$lineNr], $maxVal);
	$maxVal = max($results->{$worseSysId}->{$set}->{$lp}->[$lineNr], $maxVal);
	$minVal = min($results->{$betterSysId}->{$set}->{$lp}->[$lineNr], $minVal);
	$minVal = min($results->{$worseSysId}->{$set}->{$lp}->[$lineNr], $minVal);
}

my $distVal = $maxVal - $minVal;

for my $sysId (sort { lc($a) cmp lc($b) } keys %$results) {
	my $h2 = $results->{$sysId};
	
	for my $set (sort keys %$h2) {
		my $h3 = $h2->{$set};
		
		for my $lp (sort keys %$h3) {
			my $a4 = $h3->{$lp};
			
			for my $lineNr (0..$#$a4) {
				my $rawScore = $a4->[$lineNr];
				
				my $normScore = 0.1 + 0.9 * ($rawScore - $minVal) / $distVal;
				
				my @toPrint = ($metricName, $lp, $set, $sysId, $lineNr+1, sprintf("%.5f", $normScore));
				
				if ($sysLvl) {
					splice(@toPrint, 4, 1);
				}
				
				print join("\t", @toPrint) . "\n";
			}
		}
	}
}

#####
#
#####
sub max {
	my ($a, $b) = @_;
	return (($a > $b)? $a: $b);
}

#####
#
#####
sub min {
	my ($a, $b) = @_;
	return (($a < $b)? $a: $b);
}
