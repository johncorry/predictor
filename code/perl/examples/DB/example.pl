#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use My::Predict::DB;
use Lingua::EN::Numbers qw(num2en);

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

for (my $i = 1; $i <= 20; $i++) {
   
    my $number = $i;
    my $text = num2en($i);

    print "$number" .  "\t" .  "$text" . "\n";

    $sth = $dbh->prepare("INSERT INTO Test 
                         (Number,Text)
                          values
                          ('$number',
                           '$text')
                          ON DUPLICATE KEY UPDATE
                          Text = '$text'");

    $sth->execute()
      or die "Error inserting record: " . $dbh->errstr;
}
 
$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
