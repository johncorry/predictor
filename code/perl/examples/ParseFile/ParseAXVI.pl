#!/usr/bin/perl

use strict;
use warnings;
 
use Finance::QuoteHist;
use File::Fetch;
use DBI;
use Time::Piece;
use DateTime;
#use Time::ParseDate;
use My::Predict::DB;

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

my $filename = 'AXVI.csv';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
my $count = 0;
my $code = "^AXVI";

while (<$fh>){

   my $content = $_;
   my @rows = split(/,/,$content);
   #print "Before -> " . $rows[0] . "\n";
   my @date_tokens = split(/\//,$rows[0]);
   my $date = "20" . $date_tokens[2] . "-" . $date_tokens[1] . "-" . $date_tokens[0]; 
   my $close = $rows[1];
   print "Insert date for $date $code $close\n";

   my $sth2 = $dbh->prepare("INSERT INTO PriceData.ASXETF
                            (Date,Code,Close)
                            values
                            ('$date',
                             '$code',
                             '$close')");
   $sth2->execute();
   $sth2->finish();

}

close ($fh);

