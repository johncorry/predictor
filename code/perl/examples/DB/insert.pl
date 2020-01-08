#!/usr/bin/perl

use strict;
use DBI;
use Time::Piece;

my $dbh = DBI->connect(          
    "dbi:mysql:PriceData:datastore.c6lgnooprssz.ap-southeast-2.rds.amazonaws.com",
    "jcorry",                          
    "iona22",                          
    { RaiseError => 1 },         
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();

my $ver = $sth->fetch();

print @$ver;
print "\n";

#my $date = Time::Piece->strptime('12/22/13 21:48:06', '%D %T');
#print $date->strftime('%F %T');

my $code = "0J?";
my $open = 1.0;
my $high = 1.02;
my $low = 0.99;
my $close = 1.01;
my $vol = 10000;
my $adjClose = 1.01;
my $inc = 0.01;

foreach my $day(1 .. 31){

  my $date = "2014-12-$day 00:00:00";
  print "$date\n";

  $sth = $dbh->prepare("INSERT INTO ASX200Price 
                       (Date, Code, Open, High, Low, Close, Volume, AdjClose)
                       values
                       ('$date', '$code', '$open', $high, '$low', '$close', '$vol', '$adjClose')");

  $sth->execute() or die $DBI::errstr;

  $open = $open + $inc;
  $high = $high + $inc;
  $low = $low + $inc;
  $close = $close + $inc;
  $vol = $vol + 100;
  $adjClose = $adjClose + $inc;

}

$sth->finish();
$dbh->disconnect();
