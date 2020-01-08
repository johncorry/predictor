#!/usr/bin/perl

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;
use Getopt::Long;

use My::Predict::ASX200Data;


print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";

my $ASX200Data = new ASX200Data();

my $codes_arr_ref = $ASX200Data->getCodes();
my $counter = 0;

foreach my $code (@$codes_arr_ref) {
  print "Result Counter : $code $counter\n";

  my $cmd = "/home/ubuntu/code/perl/predict/modelC/searchPredict.pl -s -c " . $code . " > /dev/null 2>&1";
  #print $cmd . "\n";
  system ($cmd);
  print "Result " . localtime . "\n";
  
  $counter++;

  #if ($counter > 30) {
  #   exit;
  #}
}

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";

