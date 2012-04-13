#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use parse;
use io;

our @mainkeys = (qw(miss punct extr untr lex-dis diffpos infl ord-s ord-l));

my $stats = {};

my $filename = "-";

my $fh = io::openRead($filename);
binmode(STDOUT, ":utf8");

our $doSysLev = ($ARGV[1] eq "system");

my $posDictFile = $ARGV[0];
our $doPosTags = defined($posDictFile);
our $posDict = loadPosDict($posDictFile);

our $bogusVector = join(",", ((0) x (1 + (scalar keys %{$posDict->{'tags'}}) * ((scalar @mainkeys) - 1)))) . "\n";

our $totalSysVector = { 'hyplength' => 0, 'counts' => [] };

while (<$fh>) {
	my $tag = parse::xml($_);
	
	if (defined($tag)) {
		my $tagId = $tag->{'id'};
		my $fields = $tag->{'fields'};
		
		if ($tagId eq "sentence") {
			$stats = {};
		}
		elsif ($tagId eq "hypothesis") {
			$stats->{'hyplength'} = 0 + $fields->{'length'};
		}
		elsif ($tagId eq "reference") {
			$stats->{'reflength'} = 0 + $fields->{'length'};
		}
		elsif ($tagId =~ /^(missingRefWord|extraHypWord|untranslatedHypWord)$/) {
			my $errType = undef;
			
			if (tokIsPunct($fields->{'token'})) {
				$errType = 'punct';
			}
			else {
				$errType = substr($tagId, 0, 4); # 'miss'/'extr'/'untr'
				
				if ($doPosTags) {
					$errType .= "_" . $posDict->{'dict'}->{getPos($fields->{'token'})};
				}
			}
			
			upd($stats, $errType);
		}
		elsif ($tagId eq "unequalAlignedTokens") {
			my %uneqs = map { $_ + 0 => 1 } split(/,/, $fields->{'unequalFactorList'});
			
			my $errType = undef;
			
			if (tokIsPunct($fields->{'hypToken'}) or tokIsPunct()) {
				$errType = 'punct';
			}
			else {
				if ($uneqs{2}) {
					$errType = 'lex-dis';
				}
				elsif ($uneqs{1}) {
					$errType = 'diffpos';
				}
				else {
					$errType = 'infl';
				}
				
				if ($doPosTags) {
					$errType .= "_" . $posDict->{'dict'}->{getPos($fields->{'hypToken'})};
				}
			}
			
			upd($stats, $errType);
		}
		elsif ($tagId eq "ordErrorSwitchWords") {
			my $errType = undef;
			
			if (tokIsPunct($fields->{'hypToken1'}) or tokIsPunct($fields->{'hypToken2'})) {
				$errType = 'punct';
			}
			else {
				$errType = 'ord-s';
				
				if ($doPosTags) {
					$errType .= "_" . $posDict->{'dict'}->{getPos($fields->{'hypToken1'})};
				}
			}
			
			upd($stats, $errType);
		}
		elsif ($tagId eq "ordErrorShiftWord") {
			my $errType = undef;
			
			if (tokIsPunct($fields->{'hypToken'})) {
				$errType = 'punct';
			}
			else {
				$errType = 'ord-l';
				
				if ($doPosTags) {
					$errType .= "_" . $posDict->{'dict'}->{getPos($fields->{'hypToken'})};
				}
			}
			
			upd($stats, $errType);
		}
		elsif ($tagId eq "/sentence") {
			my $outVec = genOutVec($stats);
			
			if ($doSysLev) {
				addVec($outVec);
			}
			else {
				showVec($outVec);
			}
		}
	}
}

if ($doSysLev) {
	showVec($totalSysVector);
}

#####
#
#####
sub upd {
	my ($stats, $errType) = @_;
	
	$stats->{$errType}++;
}

#####
#
#####
sub setMaybeFlag {
	my ($hypSnt, $idx, $flag, $rawToken, $override) = @_;
	
	if (!$override) {
		my $surForm = io::getWordFactor($hypSnt->{'hyp'}->[$idx]->{'factors'}, 0);
		my $pos = io::getWordFactor(parse::token($rawToken, 1));
		
		if ($surForm =~ /^[[:punct:]]+$/ or $pos eq "punct" or $pos eq "P") {
			$flag = "punct";
		}
	}
	
	$hypSnt->{'hyp'}->[$idx]->{'flags'}->{$flag} = 1;
}

#####
#
#####
sub genOutVec {
	my ($stats) = @_;
	
	my $result = {
		'hyplength' => $stats->{'hyplength'},
		'reflength' => $stats->{'reflength'},
		'counts' => []
		};
	
	for my $k (@mainkeys) {
		my $key = $k;
		
		if ($doPosTags and $key ne "punct") {
			for my $pos (keys %{$posDict->{'tags'}}) {
				$key = $k . "_" . $pos;
				#my $val = ($stats->{'length'}? $stats->{$key} / $stats->{'length'}: 0);
				#push @out, int(1e6 * $val) / 1e6;
				push @{$result->{'counts'}}, $stats->{$key} + 0;
			}
		}
		else {
			#my $val = ($stats->{'length'}? $stats->{$key} / $stats->{'length'}: 0);
			#push @out, int(1e6 * $val) / 1e6;
			push @{$result->{'counts'}}, $stats->{$key} + 0;
		}
	}
	
	return $result;
	
	#print join(",", @out) . "\n";
}

#####
#
#####
sub showVec {
	my ($vec) = @_;
	
	my $missSize = ($doPosTags? (scalar keys %{$posDict->{'tags'}}): 1);
	
	my $hlen = $vec->{'hyplength'};
	my $rlen = $vec->{'reflength'};
	
	my @res = ();
	
	for my $i (0..$#{$vec->{'counts'}}) {
		my $count = $vec->{'counts'}->[$i];
		
		my $len = ($i < $missSize)? $rlen: $hlen;
		push @res, ($len? (int(1e6 * $count / $len) / 1e6): 0);
	}
	
	print join(",", @res) . "\n";
}

#####
#
#####
sub addVec {
	my ($vec) = @_;
	
	$totalSysVector->{'hyplength'} += $vec->{'hyplength'};
	$totalSysVector->{'reflength'} += $vec->{'reflength'};
	
	for my $i (0..$#{$vec->{'counts'}}) {
		$totalSysVector->{'counts'}->[$i] += $vec->{'counts'}->[$i];
	}
}

#####
#
#####
sub getPos {
	my ($tok) = @_;
	
	my ($surf, $pos) = split(/\|/, $tok);
	
	return $pos;
}

#####
#
#####
sub tokIsPunct {
	my ($tok) = @_;
	
	my ($surf) = split(/\|/, $tok);
	
	return ($surf =~ /^[[:punct:]]+$/);
}

#####
#
#####
sub loadPosDict {
	my ($fn) = @_;
	
	if ($doPosTags) {
		my $result = {};
		
		open(FH, $fn) or die ("Failed to open `$fn' for reading");
		
		while (<FH>) {
			s/[\n\r]//g;
			my ($rawTag, $tag) = split(/\t/, lc($_));
			
			#this replaces generalized tags with detailed original ones
			#$tag = $rawTag;
			
			$result->{'tags'}->{$tag} = 1;
			$result->{'dict'}->{$rawTag} = $tag;
		}
		
		close(FH);
		
		return $result;
	}
	else {
		return { 'tags' => { 'all' => 1 } };
	}
}
