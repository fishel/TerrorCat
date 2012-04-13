#!/usr/bin/perl
use strict;

my $stats = {};

while (<STDIN>) {
	if (/^(..-..),([^,]+),([0-9]+),(.*)$/) {
		my ($lp, $set, $idx, $rawRanks) = ($1, $2, $3, $4);
		
		my $count = 0;
		my @bestSysList = ();
		my $bestRank = 10;
		
		my @toks = split(/,/, $rawRanks);
		
		my $rankList = regrp(@toks);
		
		if ($#$rankList > 0) {
			for my $i (1..$#$rankList) {
				for my $j (0..($i-1)) {
					my ($xi, $xj) = ($rankList->[$i], $rankList->[$j]);
					my ($ri, $si, $rj, $sj) = ($xi->{'rank'}, $xi->{'sys'}, $xj->{'rank'}, $xj->{'sys'});
					
					$stats->{$set}->{$lp}->{$si}->{'all'}++;
					$stats->{$set}->{$lp}->{$sj}->{'all'}++;
					
					if ($ri <= $rj) {
						$stats->{$set}->{$lp}->{$si}->{'win'}++;
					}
					
					if ($rj <= $ri) {
						$stats->{$set}->{$lp}->{$sj}->{'win'}++;
					}
				}
			}
		}
	}
	else {
		warn("Almost choked on `$_'");
	}
}

for my $set (sort keys %$stats) {
	my $setStats = $stats->{$set};
	
	for my $lp (sort keys %$setStats) {
		my $lpStats = $setStats->{$lp};
		
		for my $sys (sort keys %$lpStats) {
			print join("\t", "HUMAN_RANK", $lp, $set, $sys, sprintf("%.4f", $lpStats->{$sys}->{'win'} / $lpStats->{$sys}->{'all'})) . "\n";
		}
	}
}

sub regrp {
	my @toks = @_;
	
	my $result = [];
	
	while (@toks > 0) {
		my ($sys, $rank) = splice(@toks, 0, 2);
		
		unless ($rank == -1) {
			push @$result, { 'sys' => $sys, 'rank' => $rank + 0 };
		}
	}
	
	return $result;
}
