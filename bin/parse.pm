package parse;
use strict;

#####
#
#####
sub token {
	my ($str) = @_;
	return [ split(/\|/, $str) ]
}

#####
#
#####
sub sentence {
	my ($string, $caseSensitive) = @_;
	my @result;
	
	if (!$caseSensitive) {
		$string = lc($string);
	}
	
	my @tokens = split(/ /, $string);
	
	for my $token (@tokens) {
		push @result, token($token);
	}
	
	return \@result;
}

#####
#
#####
sub alignment {
	my ($string, $ignoreDuplicates, $maxRef, $maxHyp) = @_;
	my @result;
	
	my ($refHash, $hypHash) = ({}, {});
	
	my @tokens = split(/ /, $string);
	
	for my $token (@tokens) {
		if ($token =~ /^([0-9]+)-(-1|[0-9]+)$/) {
			my ($hyp, $ref) = ($1, $2);
			
			if (!$ignoreDuplicates and $hypHash->{$hyp}) {
				die("Alignment has to be 1-to-1, duplicate hyp point $hyp '$string'");
			}
			else {
				$hypHash->{$hyp} = 1;
			}
			
			if (!$ignoreDuplicates and $refHash->{$ref}) {
				die("Alignment has to be 1-to-1, duplicate ref point $ref in '$string'");
			}
			else {
				$refHash->{$ref} = 1;
			}
			
			if ($hyp >= 0 and $hyp <= $maxHyp and $ref >= 0 and $ref <= $maxRef) {
				push @result, { 'hyp' => $hyp, 'ref' => $ref };
			}
		}
		else {
			my $msg = "Failed to parse `$token' as an alignment pair";
			die($msg);
		}
	}
	
	return \@result;
}

#####
#
#####
sub morepts {
	my ($string, $result, $maxRef, $maxHyp) = @_;
	
	my $alParse = alignment($string, 1, $maxRef, $maxHyp);
	
	for my $alPt (@$alParse) {
		$result->{$alPt->{'hyp'}}->{$alPt->{'ref'}}++;
	}
}

#####
#
#####
sub xmlTagFields {
	my $str = shift;
	my $resultHash = {};
	
	while ($str =~ /^\s+([^=[:space:]]+)="([^"]*)"(.*)\s*$/) {
		my $fieldName = $1;
		my $fieldValue = $2;
		$str = $3;
		
		#in case the field value includes a \"
		#while ($fieldValue =~ /\\$/) {
		#	if ($str =~ /([^"]*)"(.*)\s*$/) {
		#		print STDERR "!!! $1 !! $2 !\n";
		#		$fieldValue .= "\"" . $1;
		#		$str = $2;
		#	}
		#	else {
		#		die("Failed to parse a field value with a double quote inside: `$str'");
		#	}
		#}
		
		$resultHash->{$fieldName} = $fieldValue;
	}
	
	if ($str !~ /^\s*$/) {
		die ("String left-overs from parsing xml tag fields: `$str'");
	}
	
	return $resultHash;
}

#####
#
#####
sub xml {
	my $str = shift;
	
	$str =~ s/\n//g;
	$str =~ s/\/(>\s*)$/$1/g;
	
	if ($str =~ /^\s*<\s*(\S+)(.*)>\s*$/) {
		my $tagId = $1;
		my $fieldStr = $2;
		
		return {'id' => $tagId,
			'fields' => xmlTagFields($fieldStr) };
	}
	elsif ($str =~ /^\s*$/) {
		return undef;
	}
	else {
		die("Failed to parse XML from string `$str'");
	}
}

#####
#
#####
sub parseFlaggTokFlags {
	my ($flagStr, $joinLexAndDisam) = @_;
	
	my $isMissingRef = undef;
	my $pos = undef;
	my $isWrongHyp = undef;
	
	my $flags = {};
	
	if ($flagStr ne "") {
		my @flagList = split(/::/, $flagStr);
		
		for my $flag (@flagList) {
			if ($flag eq "neg") {
				$flag = "form";
			}
			#if ($joinLexAndDisam and $flag eq "disam") {
			if ($flag eq "disam") {
				$flag = "lex/dism";
			}
			$flags->{$flag} = 1;
			
			if ($flag =~ /^miss(.)$/) {
				$pos = $1;
				$isMissingRef = 1;
			}
			else {
				$isWrongHyp = 1;
			}
		}
	}
	
	if ($isMissingRef and $isWrongHyp) {
		die("Conflicting flags for `$flagStr': cannot tag word as missing and erroneous at the same time");
	}
	
	return ($flags, $pos);
}

#####
#
#####
sub flagg {
	my ($snt, $joinLexAndDisam) = @_;
	
	$snt =~ s/\n//g;
	
	my $missHash = {};
	my $hypErrList; #[ { 'factors' => [], 'flags' => [] } ]
	
	for my $token (split(/ +/, $snt)) {
		if ($token =~ /^(([^ :]+::)*)([^ ]+)$/) {
			my $tokStr = $3;
			my $flagStr = $1;
			
			my ($flags, $pos) = parseFlaggTokFlags($flagStr, $joinLexAndDisam);
			
			if ($pos) {
				$missHash->{"$tokStr|$pos"}++;
			}
			else {
				push @$hypErrList, { 'factors' => [$tokStr], 'flags' => $flags };
			}
		}
		else {
			die("Failed to parse `$token' into a token");
		}
	}
	
	return { 'hyp' => $hypErrList, 'missed' => $missHash };
}

1;
