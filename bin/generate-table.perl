#!/usr/bin/perl

# This script formats all of the system-level rankings from the automatic evaluation
# metrics into a bunch of tables.

@all_metrics = ( "HUMAN_RANK" );


while($line = <>) {
    chomp $line;
    ($metric, $langPair, $testSet, $system, $score) = split(/\s+/, $line);
    $metrics{$metric} = 1;
    $langPairs{$langPair} = 1;
    $testSets{$testSet} = 1;
    $systems{$system} = 1;
    



    $scored{$langPair}{$testSet}{$metric} = 1;
    $exists{$langPair}{$testSet} = 1;
    if($partipated{$langPair}{$testSet}{$system} == 0) {
	$numSystems{$langPair}{$testSet}++;
    }

    $partipated{$langPair}{$testSet}{$system} =1;
    $scores{$langPair}{$testSet}{$system}{$metric} = $score;
    if($highestScore{$langPair}{$testSet}{$metric} < $score) {
	$highestScore{$langPair}{$testSet}{$metric} = $score;
    }
    

}
close(FILE);


# sort the metrics so that the human ones are at the start.
foreach $metric (@all_metrics) {
    $metrics{$metric} = 0;
}
foreach $metric (sort keys %metrics) {
    if($metrics{$metric} != 0) {
	push(@all_metrics, $metric); 
    }
}







foreach $langPair (sort keys %langPairs) {
    foreach $testSet (sort keys %testSets) {

	if($exists{$langPair}{$testSet} == 1 && $numSystems{$langPair}{$testSet} > 1) {
#	    print "--------------\n";
	    print "$langPair $testSet\n";
	    foreach $metric (@all_metrics) {
		if($scored{$langPair}{$testSet}{$metric} == 1) {
		    print "\t$metric";
		}
	    }
	    print "\n";
	    
	    foreach $system (sort keys %systems) {
		if($partipated{$langPair}{$testSet}{$system} == 1) {
		    print "$system";
		    foreach $metric (@all_metrics) {
			if($scored{$langPair}{$testSet}{$metric} == 1) {
			    $score = $scores{$langPair}{$testSet}{$system}{$metric};
			    if($score == 0) {
				$score = "n/a";
			    }
			    # check to see if it's the highest scoring one...
			    if($score == $highestScore{$langPair}{$testSet}{$metric}) {
#				$score = $score . "*";
			    }
			    print "\t$score";
			}
		    }
		    print "\n";
		}
	    }
	}
    }
}
