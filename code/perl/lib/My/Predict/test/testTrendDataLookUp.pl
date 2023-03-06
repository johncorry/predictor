#!/usr/bin/perl

use strict;
use warnings;

use My::Predict::ASX200Data;

my $ASX200Data = new ASX200Data();

print "\nTest 1:\n";
print $ASX200Data->getStartDate() . "\n";


print "\nTest 2:\n";
my $testCode = "0J?";
my $priceMap_ref = $ASX200Data->getPriceSeries($testCode);
my $dateSeries_ref = $ASX200Data->getDateSeries($testCode);

foreach my $date (@$dateSeries_ref){
  $$priceMap_ref{$date}->print();
}

print "Finished.\n";

