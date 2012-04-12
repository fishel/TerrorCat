#!/usr/bin/perl
use strict;

my ($fhHjerr, $fhHyp, $fhRef, $fhDict) = map { fopen($_) } @ARGV[0..3];

my $doSysLev = ($ARGV[4] eq "system");

our @errList = (qw(miss reord infl lex infl));

my @hypSnts = map { parseFactored($_) } <$fhHyp>;
my @refSnts = map { parseFactored($_) } <$fhRef>;

close($fhHyp);
close($fhRef);

my $posDict = loadPosDict($fhDict);

our @tagList = sort keys %{$posDict->{'tags'}};

my $scores = {};
my $refLen = undef;
my $hypLen = undef;

while (<$fhHjerr>) {
	s/[\n\r]//g;
	
	if (/^\s*$/) {
		unless ($doSysLev) {
			display($scores);
			
			($scores, $refLen, $hypLen) = ({}, 0, 0);
		}
	}
	else {
		my ($idx, $hypRef, $snt) = parseHjerr($_);
		
		#print "$idx // $hypRef // @$snt;\n";
		
		my $posBearer = ($hypRef eq "hyp")? $hypSnts[$idx]: $refSnts[$idx];
		
		if ($hypRef eq "hyp") {
			$hypLen += scalar @$posBearer;
		}
		else {
			$refLen += scalar @$posBearer;
		}
		
		my $tokIdx = 0;
		
		for my $err (@$snt) {
			#print "DEBUG $err / $hypRef / " . $posBearer->[$tokIdx] . ";\n";
			if ((($err eq "miss") == ($hypRef eq "ref")) and ($err ne "x")) {
				$scores->{$err . "_" . $posDict->{'dict'}->{$posBearer->[$tokIdx]}}++;
			}
			
			$tokIdx++;
		}
	}
}

close($fhHjerr);
close($fhDict);

if ($doSysLev) {
	display($scores);
}

#####
#
#####
sub display {
	my ($sc) = @_;
	
	my @outFeats = ();
	
	for my $err (@errList) {
		my $baseLen = (($err eq "miss")? $refLen: $hypLen);
		
		for my $tag (@tagList) {
			push @outFeats, ($baseLen? (int(1e6 * $sc->{$err . "_" . $tag} / $baseLen) / 1e6): 0);
		}
	}
	
	print join(",", @outFeats) . "\n";
}

#####
#
#####
sub parseFactored {
	my ($str) = @_;
	
	$str =~ s/[\r\n]//g;
	
	my @result = map { my ($surf, $pos) = split(/\|/); $pos } split(/ /, lc($str));
	
	return \@result;
}

#####
#
#####
sub parseHjerr {
	my ($str) = @_;
	
	if ($str =~ /^([0-9]+)::(hyp|ref)-err-cats: (.*)$/) {
		my ($idx, $hypRef, $rawSnt) = ($1, $2, $3);
		
		$rawSnt =~ s/\s+/ /g;
		$rawSnt =~ s/^ //g;
		$rawSnt =~ s/ $//g;
		
		my @errs = map { my ($surf, $err) = split(/~~/); $err } split(/ /, $rawSnt);
		
		return ($idx - 1, $hypRef, \@errs);
	}
	else {
		die("Choked on `$str'");
	}
}

#####
#
#####
sub fopen {
	my ($name) = @_;
	
	my $fh;
	
	open($fh, $name) or die("Failed to open `$name' for reading");
	
	return $fh;
}

#####
#
#####
sub loadPosDict {
	my ($fh) = @_;
	
	my $result = {};
	
	while (<$fh>) {
		s/[\n\r]//g;
		my ($rawTag, $tag) = split(/\t/, lc($_));
		
		#print "DEBUG $rawTag -> $tag;\n";
		
		#this replaces generalized tags with detailed original ones
		#$tag = $rawTag;
		
		$result->{'tags'}->{$tag} = 1;
		$result->{'dict'}->{$rawTag} = $tag;
	}
	
	return $result;
}

#####
#
#####
sub tokIsPunct {
	my ($tok) = @_;
	
	my ($surf) = split(/\|/, $tok);
	
	return ($surf =~ /^[[:punct:]]+$/);
}
