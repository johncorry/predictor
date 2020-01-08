#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Time::Piece;

use My::Predict::Problem;
use My::Predict::Solver;


print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";


my $code = 'QAN';
my $forecastPeriod = 10;
my $upperThreshold = "0.01";
my $lowerThreshold = "-0.01";
my $numTests = 100;
my $timeSeries = 5;
my $timeMachine = 0;
my $print = 0;

my $search = 0;
my $includeIndex       = 0;
my $includeETFs        = 0;
my $includeFX          = 0;
my $includeDaysMonths  = 0;
my $includeTimeSeries  = 0;
my $includeFrequencies = 0;

my $result = GetOptions ("c=s"  => \$code,
                         "f=i"  => \$forecastPeriod,
                         "ut=f" => \$upperThreshold,
                         "lt=f" => \$lowerThreshold,
                         "nt=i" => \$numTests,
                         "ts=i" => \$timeSeries,
                         "tm=i" => \$timeMachine,
                         "p"    => \$print,
                         "INCLUDE_INDEX"       => \$includeIndex,
                         "INCLUDE_ETFS"        => \$includeETFs,
                         "INCLUDE_FX"          => \$includeFX,
                         "INCLUDE_DAYS_MONTHS" => \$includeDaysMonths,
                         "INCLUDE_TIMESERIES"  => \$includeTimeSeries,
                         "INCLUDE_FREQS"       => \$includeFrequencies,
);

my $problem = new Problem($code,$forecastPeriod,$timeMachine);
my $solver = new Solver($problem);

$problem->setUpperThreshold($upperThreshold);
$problem->setLowerThreshold($lowerThreshold);
$problem->includeIndex($includeIndex);
$problem->includeETFs($includeETFs);
$problem->includeFX($includeFX); #FIXME This is returning BAD
$problem->includeDaysMonths($includeDaysMonths);
$problem->includeTimeSeries($includeTimeSeries);
$problem->includeFrequencies($includeFrequencies);

print "Result\nResult Trying to predict $code....\n";
$problem->printParameters;
$problem->createProblem;

my $itCount = 0;

while ($itCount < 1) { 

   $solver->train;
   $solver->predict;

   my ($prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy) = $problem->getSolution($print);
   print "Result Solution  $prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy\n";
   $itCount++; 
}

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";

