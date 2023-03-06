#!/usr/bin/perl

use strict;
use warnings;

use Finance::QuoteHist;
use File::Fetch;
use DBI;
use Time::Piece;
use DateTime;
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

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();
$sth->finish();

#my $start_date = new Date::Manip::Date;
#my $end_date = new Date::Manip::Date;

#$start_date->parse("14 days ago");
#$end_date->parse("Today");

# ETPMAG.ax - Silver
# OOO.ax  - Oil
# RCB.ax  - Bonds
# BNKS.ax - Global banks
# QCB.ax  - Broad commodities
# QAG.ax  - Agriculture
# QAU.ax  - Gold
# QOZ.ax  - FTSE RAFI Australia 200
# QFN.ax  - Financials
# QPON.ax - Australia Banking Senior Floating Rate Bond
# QUAL.ax - MSCI World ex Australia Quality Index
# QUS.ax  - FTSE RAFI US 1000
# TECH.ax - Global tech
# YANK.ax
# FOOD.ax
# NDQ.ax  - NASDAQ
# ^AXVI Only seems to be available for a day.

my $numWeeks = 4;

for (my $i = $numWeeks; $i >= 1; $i--) {

   my $start = $i * 7 - 1;
   my $end = $start - 6;
   print "$start...$end\n";                # Countdown

   my $q = Finance::QuoteHist->new
      (
         symbols    => [qw( ETPMAG.ax ^AXVI OOO.ax RCB.ax BNKS.ax QCB.ax QAG.ax QAU.ax QOZ.ax QFN.ax QPON.ax QUAL.ax QUS.ax TECH.ax YANK.ax FOOD.ax NDQ.ax )],
         start_date => "$start days ago", # or '1 year ago', see Date::Manip
         end_date   => "$end days ago",
      );

   # Quotes
   foreach my $row ($q->quotes()) {
     (my $code, my $date, my $open, my $high, my $low, my $close, my $volume) = @$row;

     $code =~ s/\.ax//;
     $date =~ s/\//\-/g;

     print "Inserting data for ". $date . " " . $code . " " . $close . "\n";

     my $sth2 = $dbh->prepare("INSERT INTO PriceData.ASXETF
                              (Date,Code,Open,High,Low,Close,Volume)
                              values
                              ('$date',
                               '$code',
                               '$open',
                               '$high',
                               '$low',
                               '$close',
                               '$volume')");
     $sth2->execute();
     $sth2->finish();

   }
}

$dbh->disconnect();
$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
