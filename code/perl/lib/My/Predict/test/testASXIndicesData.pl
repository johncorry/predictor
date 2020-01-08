#!/usr/bin/perl

use strict;
use warnings;

use My::Predict::ASXIndicesData;

my $ASXIndicesData = new ASXIndicesData();

print "\nTest 1:\n";
print $ASXIndicesData->getStartDate() . "\n";


print "\nTest 2:\n";
#my $testCode = "0J?";
my $testCode = "CBA";
my $indexCode = $ASXIndicesData->getIndexCode($testCode);
print "$testCode is in $indexCode sector.\n";

print "\nTest 3:\n";
my $indexMap_ref = $ASXIndicesData->getIndexSeries($indexCode);
my $dateSeries_ref = $ASXIndicesData->getDateSeries($indexCode);

foreach my $date (@$dateSeries_ref){
  $$indexMap_ref{$date}->print();
}

print "Finished.\n";

