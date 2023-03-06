#!/usr/bin/perl

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;
use My::Predict::Problem;
use My::Predict::ASX200Data;


print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";

my $ASX200Data = new ASX200Data();

my $codes_arr_ref = $ASX200Data->getValidCodes();
my $counter = 0;
my $predictable = 0;

foreach my $code (@$codes_arr_ref) {
  $counter++;
  print "Result Counter : $code $counter\n";

  my $problem = new Problem($code);
  print "Result Predicting " . $problem->getCode() . "\n";

  if ($problem->canPredict)
  {
     print "Yes\n";
     $predictable++;
  }
}

print "Result Total = $counter\n";
print "Result Predictable = $predictable\n";

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";
