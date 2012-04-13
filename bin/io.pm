package io;
use strict;

#####
#
#####
sub noRead {
	die("Failed to open `" . $_[0] . "' for reading");
}

#####
#
#####
sub openRead {
	my $filename = shift;
	
	my $fh;
	
	open($fh, $filename) or noRead($filename);
	binmode($fh, ":utf8");
	
	return $fh;
}



#------------------------------------------------------------------------------
# Opens a file for reading. If the file is gzipped, opens a pipe through gzip.
# Returns the file handle. Throws an exception if the file cannot be opened.
#------------------------------------------------------------------------------
sub gopenRead
{
    my $filename = shift;
    if($filename =~ m/\.gz$/)
    {
        $filename = "gunzip -c $filename |";
    }
    return openRead($filename);
}



#####
#
#####
sub openMany {
	my @fhs = ();
	for my $file (@_) {
		push @fhs, openRead($file);
	}
	return @fhs;
}



#------------------------------------------------------------------------------
# Opens several potentially gzipped files for reading and returns an array of
# file handles. Same as openMany() but uses gopenRead() instead of openRead().
#------------------------------------------------------------------------------
sub gopenMany
{
    my @fhs = ();
    for my $file (@_)
    {
        push(@fhs, gopenRead($file));
    }
    return @fhs;
}



#####
#
#####
sub closeMany {
	for my $fh (@_) {
		close($fh);
	}
}

#####
#
#####
sub getWordFactor {
	my ($word, $factor) = @_;
	
	my $result = $word->[$factor];
	
	if (!$result or $result =~ /^@.*@$/ or $result eq "<unknown>") {
		$result = $word->[0];
	}
	
	return $result;
}

#####
#
#####
sub readSentence {
	my $fh = shift;
	
	my $string = <$fh>;
	
	if ($string) {
		$string =~ s/\n//g;
		$string =~ s/[ \t]{2,}/ /g;
		$string =~ s/^ //g;
		$string =~ s/ $//g;
		
		return $string;
	}
	else {
		return undef;
	}
}

#####
#
#####
sub readSentences {
	my @fhArr = @_;
	my @sntArr = ();
	
	my $allFinished = 1;
	my $allSucceeded = 1;
	
	for my $fh (@fhArr) {
		my $snt = readSentence($fh);
		
		if (defined($snt)) {
			$allFinished = undef;
		}
		else {
			$allSucceeded = undef;
		}
		
		push @sntArr, $snt;
	}
	
	if ($allSucceeded) {
		return \@sntArr;
	}
	elsif ($allFinished) {
		return undef;
	}
	else {
		confess("Unequal number of lines in the input files");
	}
}

#####
#
#####
sub hashFactors {
	my ($snt, $alFactor) = @_;
	
	#make a hash/bag of ref word factors
	my $result = {};
	for my $w (@$snt) {
		$result->{getWordFactor($w, $alFactor)} = 1;
	}
	
	return $result;
}

#####
#
#####
sub str4xml {
	my $str = shift;
	
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
	
	return $str;
}

#####
#
#####
sub xml2str {
	my $str = shift;
	
    $str =~ s/&amp;/&/g;
    $str =~ s/&lt;/</g;
    $str =~ s/&gt;/>/g;
    $str =~ s/&quot;/"/g;
	
	return $str;
}

#####
#
#####
sub tok2str4xml {
    # Expected one parameter: an array reference.
	my ($token) = @_;
	return str4xml(join("|", @$token));
}

#####
#
#####
sub snt2txtFact {
	my ($snt) = @_;
	my @resArr = ();
	
	for my $w (@$snt) {
		push @resArr, join("|", @$w[0,1,2]);
	}
	
	return str4xml(join(" ", @resArr));
}

#####
#
#####
sub snt2txt {
	my ($snt) = @_;
	my @resArr = ();
	
	for my $w (@$snt) {
		push @resArr, $w->[0];
	}
	
	return str4xml(join(" ", @resArr));
}

1;
