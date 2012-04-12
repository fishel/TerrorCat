#!/usr/bin/perl
use strict;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');

my $factor = shift @ARGV;

if (!defined($factor)) {
	$factor = 0;
}

while (<STDIN>) {
	s/[\n\r]//g;
	my @tokens = split(/ /);
	my @factors = map { getFact($_, $factor) } @tokens;
	
	my $output = lc(join(" ", @factors)) . "\n";
	
	$output =~ s/#/_/g;
	
	print $output;
}

#####
#
#####
sub getFact {
	my ($str, $idx) = @_;
	
	my @factors = split(/\|/, $str);
	my $result = @factors[$idx];
	
	if (length($result) == 0) {
		die("String `$str' has an invalid factor `$idx'");
	}
	
	return $result;
}
