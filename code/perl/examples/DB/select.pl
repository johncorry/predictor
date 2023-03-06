#!/usr/bin/perl

use strict;
use DBI;
use Time::Piece;
use Date::Manip;
use My::Predict::DB;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

# Open DB connection.
my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT * FROM PriceData.ASX200Company 
                          WHERE LastDate > ? 
                          AND Sector <> ?"); 

my $date = new Date::Manip::Date;
$date->parse("14 days ago");
my $date_str = $date->printf("%Y-%m-%d");

print $date_str . "\n";

$sth->execute($date_str,"Not Applic") or die $DBI::errstr;

while (my @row = $sth->fetchrow_array()) {
  print $row[0] . " " . $row[3] . "\n";
}


$sth->finish();
$dbh->disconnect();
