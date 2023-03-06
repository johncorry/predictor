#!/usr/bin/perl

use strict;
use warnings;

use My::Predict::ASX200Data;
use My::Predict::DataLookUp;

my $code = "SAR";

my $TrendData = My::Predict::DataLookUp::create_Weekly_Trend_Look_Up($code);
my $ASX200Data = new ASX200Data();
my $dateSeries = $ASX200Data->getDateSeries($code);

print "\nTest 1:\n";

for my $date_key (@$dateSeries){

  print $date_key . " " .  $TrendData->{$date_key} . "\n";
}

print "Finished.\n";

