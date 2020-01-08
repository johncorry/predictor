#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Time::Piece;

use My::Predict::DB;
use My::Predict::Problem;
use My::Predict::Solver;


print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";


my $timeMachine = 0;
my $print = 1;


# Open DB connection.
my $dbh = DBI->connect(
      $My::Predict::DB::Location,
      $My::Predict::DB::User,
      $My::Predict::DB::Pass,
      { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;


my $sth = $dbh->prepare("SELECT DISTINCT Date FROM PriceData.Prediction ORDER BY Date DESC");
$sth->execute();
#my $date = '2016-02-17';
my @row = $sth->fetchrow_array();
my $date = $row[0];

print "Result Predictions for $date....\n";

$sth = $dbh->prepare("SELECT * FROM PriceData.Prediction WHERE Date = ? AND Prediction = 1 AND Gain > 1.1 ORDER BY Gain Desc");
$sth->execute($date);

while (@row = $sth->fetchrow_array()){

   print "Result\n";
   print "Result " . $row[0] . " " . $row[1] . " " . $row[-1] . "\n";
   my @words = split / /, $row[0];
   my $date = $words[0];
   print "Result Loading prediction parameters for $date...\n";

   my $problem = new Problem($row[1],$row[2],$timeMachine);
   $problem->setUpperThreshold($row[3]);
   $problem->setLowerThreshold($row[4]);
   $problem->setTimeSeries($row[5]);
   $problem->includeIndex($row[6]);
   $problem->includeETFs($row[7]);
   $problem->includeFX($row[8]); 
   $problem->includeDaysMonths($row[9]);
   $problem->includeFrequencies($row[10]);
   $problem->includeTimeSeries($row[11]);
 
   my $solver = new Solver($problem);

   print "Result Trying to predict $row[1]....\n";

   $problem->printParameters;
   $problem->createProblem;

   #my $itCount = 0;

   #while ($itCount < 2){

      $solver->train;
      #$solver->train;
      $solver->predict;

      my ($prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy, $result) = $problem->getSolution($print);
      print "Result Solution  $prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy\n";

   #   $itCount++;
   #}
}

$sth->finish();
$dbh->disconnect();     

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";

