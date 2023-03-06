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

####################

my $sth = $dbh->prepare("SELECT * FROM PriceData.ASX200Company");
$sth->execute();

my $sth2 = $dbh->prepare("SELECT MAX(Date) FROM PriceData.ASX200Price WHERE Code = ?");


while (my @row = $sth->fetchrow_array()) {

   my $code = $row[0];
   my $name = $row[1];
   my $sector = $row[2];
   
   if ($code eq ""){
        next;
   }

   $logtime = localtime; # scalar context

   $sth2->execute($code);
   my @row2 = $sth2->fetchrow_array();
   my $maxDate = $row2[0];

   print "\n$logtime\n";

   if ($maxDate eq ""){
     print "$code has a null date so skipping.\n";
     next;
   }

   print $code . " " . $name . " " . $maxDate . "\n";

   my $sth3 = $dbh->prepare("UPDATE PriceData.ASX200Company
                             SET LastDate = '$maxDate'
                             WHERE Code = '$code'");

 
   $sth3->execute or die "Can't execute SQL statement: $DBI::errstr\n";
 
}
