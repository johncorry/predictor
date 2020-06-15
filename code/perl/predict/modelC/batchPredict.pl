#!/usr/bin/perl

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;
use Getopt::Long;
use Parallel::ForkManager;

use My::Predict::ASX200Data;

print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";

my $MAX_PROCESSES = 4;
my $ASX200Data = new ASX200Data();

my $codes_arr_ref = $ASX200Data->getCodes();
my $counter = 0;

my $pm = new Parallel::ForkManager($MAX_PROCESSES);

foreach my $code (@$codes_arr_ref) {
  print "Result Counter : $code $counter\n";

  # Forks and returns the pid for the child:
  my $pid = $pm->start and next;
    #print "PID $pid \n";
    my $cmd = "/home/ec2-user/git-checkout/code/perl/predict/modelC/searchPredict.pl -s -c " . $code . " > /dev/null 2>&1";
    #print $cmd . "\n";
    system ($cmd);
    print "Result " . localtime . "\n";
    $counter++;
  $pm->finish; # Terminates the child process

  #if ($counter > 30) {
  #   exit;
  #}
}

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";
