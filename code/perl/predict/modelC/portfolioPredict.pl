#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Time::Piece;
use Time::Seconds;

use My::Predict::DB;

my $counter = 0;

print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";

# Open DB connection.
my $dbh = DBI->connect(
      $My::Predict::DB::Location,
      $My::Predict::DB::User,
      $My::Predict::DB::Pass,
      { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;


my $sth = $dbh->prepare("SELECT Code FROM PriceData.Portfolio WHERE SaleDate IS NULL");
$sth->execute();

my @row;

while (@row = $sth->fetchrow_array()){
  my $code = $row[0];
  print "Result Counter : $code $counter\n";

  my $cmd = "/home/ec2-user/git-checkout/code/perl/predict/modelC/searchPredict.pl -s -c " . $code . " > /dev/null 2>&1";
  #print $cmd . "\n";
  system ($cmd);
  print "Result " . localtime . "\n";
  
  $counter++;

  #if ($counter > 30) {
  #   exit;
  #}
}

$sth->finish();
$dbh->disconnect();

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";


