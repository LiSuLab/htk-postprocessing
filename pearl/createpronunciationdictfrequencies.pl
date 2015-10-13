#!/usr/bin/perl5.8.5

#??????????? adds freqes onto end of dict

#Usage:
#./createpronunciationdictfrequencies.pl BNCwordFreq.txt > BNCfreqcleaned.txt (http://www.kilgarriff.co.uk/bnc-readme.html#raw)

#or 

#./createpronunciationdictfrequencies.pl BNCwordFreqcleaned.txt pronunciationDict.txt > pronunciationDictFreq.txt

use strict;

local $| = 1;

#open(FREQLIST, $ARGV[0]);
#while(<FREQLIST>){
#	my $line = $_;
#	(my $Freq, my $word) = split(/ /, $line);
#	print "$word\t$Freq\n";
#}
#close(FREQLIST);

open(PRONUCTDICT, $ARGV[1]);
while(<PRONUCTDICT>){
	my $line = $_;
	$line =~ s/\n//;
        (my $thisword) = split(/ /, $line);
	my $thisfreq = 0;
 	open(FREQLIST, $ARGV[0]);
	while(<FREQLIST>){
		my $freqline = $_;
		(my $word, my $Freq) = split(/\t/, $freqline);
		$Freq =~ s/\n//;
		if ($word eq $thisword){
			$thisfreq = $thisfreq + $Freq;
		}
	}
	close(FREQLIST);

    	print "$line $thisfreq\n" ;
	printf(STDERR "$line $thisfreq\n"); 

}
close(PRONUCTDICT);
