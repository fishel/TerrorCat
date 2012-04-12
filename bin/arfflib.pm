package arfflib;
use strict;

our $arity = undef;
our $headerPrinted = undef;

#####
#
#####
sub display {
	my ($fh, $in1, $in2, $out, $info, $skipEmpty) = @_;
	
	checkArity($in1, "1: " . $info);
	checkArity($in2, "2: " . $info);
	
	my $comb = combineData($in1, $in2, $out);
	
	unless ($headerPrinted) {
		$headerPrinted = 1;
		printHeader($fh, $comb);
	}
	
	#printVec($comb);
	printSparseVec($fh, $comb, $skipEmpty);
}

#####
#
#####
sub printVec {
	my ($vector) = @_;
	
	print join(",", @$vector) . "\n";
}

#####
#
#####
sub printSparseVec {
	my ($fh, $vector, $skipEmpty) = @_;
	
	my @output = ();
	
	for my $i (0..$#$vector) {
		my $val = $vector->[$i];
		
		if ($val) {
			push @output, "$i $val";
		}
	}
	
	unless ($skipEmpty and ((scalar @output) == 1)) {
		print $fh "{" . join(",", @output), "}\n";
	}
}

#####
#
#####
sub checkArity {
	my ($arr, $info) = @_;
	
	my $thisArity = scalar @$arr;
	
	if (!defined($arity)) {
		$arity = $thisArity;
	}
	elsif ($arity != $thisArity) {
		die("Arity $thisArity does not match the general arity $arity ($info)");
	}
}

#####
#
#####
sub combineData {
	my ($in1, $in2, $out) = @_;
	
	unless ($in1 and $in2 and $out) {
		die("Failed to combine `$in1', `$in2' and `$out'");
	}
	
	my @result;
	
	for my $i (0..$#$in1) {
		push @result, int(1e6 * ($in1->[$i] - $in2->[$i])) / 1e6;
		#push @result, int(1e6 * $in1->[$i]) / 1e6;
		#push @result, int(1e6 * $in2->[$i]) / 1e6;
	}
	
	push @result, $out;
	
	return \@result;
}

#####
#
#####
sub printHeader {
	my ($fh, $featArr) = @_;
	
	my @feats = ();
	
	for my $i (0..($#$featArr-1)) {
		$feats[$i] = "\@attribute i$i numeric";
	}
	
	$feats[$#$featArr] = "\@attribute out {TRUE,FALSE}";
	
	print $fh "\@relation relazione\n\n";
	
	print $fh join("\n", @feats) . "\n\n";
	
	print $fh "\@data\n";
}

1;
