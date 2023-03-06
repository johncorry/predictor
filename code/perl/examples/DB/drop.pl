#!/usr/bin/perl

use strict;
use DBI;
use Time::Piece;
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

my $sth = $dbh->prepare("DELETE FROM PriceData.ASXTrend"); 

$sth->execute() or die $DBI::errstr;

$sth->finish();
$dbh->disconnect();
