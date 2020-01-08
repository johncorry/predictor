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
my $forecastPeriod = 20;
my $timeMachine = 0;
my $print = 0;
my $save = 0;

my @upperThresholdValues = (0.02,0.05,0.10);
my @lowerThresholdValues = (-0.01,-0.02);
my @includeIndexValues = (1); 
my @includeETFsValues = (1); 
my @includeFXValues = (1);
my @includeDaysMonthsValues = (1);
my @includeTimeSeriesValues = (1);
my @includeFrequenciesValues = (1);

my $result = GetOptions ("c=s"  => \$code,
                         "f=i"  => \$forecastPeriod,
                         "tm=i" => \$timeMachine,
                         "p"    => \$print,
                         "s"    => \$save
);


print "Result Creating problem...\n";
my $problem = new Problem($code,$forecastPeriod,$timeMachine);
print "Result Creating solver...\n";
my $solver = new Solver($problem);
my $bestPredictedGain = 0;


print "Result Predicting " . $code . "\n";
print "Result Searching....\n";

   foreach my $upperThreshold (@upperThresholdValues){
   foreach my $lowerThreshold (@lowerThresholdValues){
   foreach my $includeIndex (@includeIndexValues){
   foreach my $includeFX (@includeFXValues){
   foreach my $includeETFs (@includeETFsValues){   
   foreach my $includeDaysMonths (@includeDaysMonthsValues){
   foreach my $includeTimeSeries (@includeTimeSeriesValues){
   foreach my $includeFrequencies (@includeFrequenciesValues){

      $problem->setUpperThreshold($upperThreshold);
      $problem->setLowerThreshold($lowerThreshold);
      $problem->includeIndex($includeIndex);
      $problem->includeETFs($includeETFs);
      $problem->includeFX($includeFX); 
      $problem->includeDaysMonths($includeDaysMonths);
      $problem->includeTimeSeries($includeTimeSeries);
      $problem->includeFrequencies($includeFrequencies);

      print "Result\nResult Trying to predict $code....\n";
      $problem->printParameters;
      $problem->createProblem;
      $solver->train;
      $solver->predict;

      my ($prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy) = $problem->getSolution($print);
      print "Result \t\t\tpred \tbest \tsit \tgain \taccu\n";
      printf ("Result Solution >>> \t$prediction \t%.2f \t%.2f \t%.2f \t%.2f\n", $bestGain, $sitAndHoldGain, $gain, $accuracy);

      if ($gain > $bestPredictedGain){
         $bestPredictedGain = $gain;

         print "Result best so far.\n";
         if ($save){
            $solver->saveResult;
         }
      }
   }
   }
   }
   }
   }
   }
   }
   }

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";

