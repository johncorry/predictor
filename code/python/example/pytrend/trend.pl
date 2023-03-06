#!/usr/bin/perl

use strict;
use warnings;

use DBI;
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

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();
$sth->finish();

system("ls", "-l" );
