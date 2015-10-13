#!/usr/bin/perl5.8.5

#This script accepts a folder full of words from HTK
#with their phone boundraies and creates a file
#suitable for inputting into cohort.pl

#Usage:
#./createwordstxtfromfiles listOfItems.list

#Where output is:
#badge: sil=0 B=22 A=33 J=38 sil=58 end=50

use strict;

#
open(STIMULILIST, $ARGV[0]);
while(<STIMULILIST>){
	next unless s/^(.*?)\.rec//;
	my $stimuli = $1;
	my $filename = "phoneboundryfiles/" . $stimuli . ".rec";
	open (THISWORD, $filename);
	my @phones = ();

	while(<THISWORD>){
		next unless !s/ sp //;
		(my $onset, my $offset, my $phone) = split(/ /, $_);
		$phone =~ s/^(.*?)\-//;
		$phone =~ s/\+(.*?)$//;
		push(@phones, [$phone, $onset]);
	}
	close(THISWORD);

	print "$stimuli:";
	for my $i (0 .. $#phones){
		print " $phones[$i][0]=$phones[$i][1]";
	}
	print "\n";
}
close(STIMULILIST);
