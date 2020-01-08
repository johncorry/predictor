#!/usr/bin/perl

use strict;
use DBI;
use Time::Piece;
use Time::Seconds;
use POSIX qw(ceil);
use My::Predict::DB;

my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();

my $ver = $sth->fetch();

print @$ver;
print "\n";

#my $date = Time::Piece->strptime('2015-06-24' ,"%Y-%m-%d");
my $date = Time::Piece->strptime(gmtime->strftime("%Y-%m-%d"),"%Y-%m-%d");

my $code = "0A?";
my $prevClose = 1;

while (1) {

  print "$date\n";
   if ($date->day eq "Sun" or $date->day eq "Sat"){
     print "Weekend!\n";
   }
   else { 
     my $open = $prevClose;
     my $high = 10.02 + sin($date->epoch);
     my $low = 9.99 + sin($date->epoch);
     my $close = 10 + sin($date->epoch) ;
     my $vol = 10000 + ceil(cos($date->epoch) * 2000);
     my $adjClose = $close;
     $prevClose = $close; 
     my $datekey = $date->strftime("%Y-%m-%d 00:00:00");   

     printf (",%.3f,%.3f,%.3f,%.3f,%d,%.3f\n",$open, $high, $low, $close, $vol, $adjClose);

     $sth = $dbh->prepare("INSERT INTO ASX200Price 
                          (Date, Code, Open, High, Low, Close, Volume, AdjClose)
                          values
                          ('$datekey', '$code', '$open', $high, '$low', '$close', '$vol', '$adjClose')");

     $sth->execute() or die $DBI::errstr;
   }

   $date = $date + ONE_DAY;
 
   if ($date > Time::Piece->strptime(gmtime->strftime("%Y-%m-%d"),"%Y-%m-%d")){
     exit;
   }
}

$sth->finish();
$dbh->disconnect();
