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

# ^AXEJ
# ^AXFJ
# ^AXHJ
# ^AXIJ
# ^AXJR
# ^AXMJ
# ^AXNJ
# ^AXPJ
# ^AXSJ
# ^AXTJ
# ^AXUJ
# ^AXXJ

my $q = Finance::QuoteHist->new
   (
      symbols    => [qw( ^AXEJ ^AXFJ ^AXHJ ^AXIJ ^AXJR ^AXMJ ^AXNJ ^AXPJ ^AXSJ ^AXTJ ^AXUJ ^AXXJ )],
      start_date => '14 days ago', # or '1 year ago', see Date::Manip
      end_date   => 'today',
   );
 
# Quotes
foreach my $row ($q->quotes()) {
  (my $code, my $date, my $open, my $high, my $low, my $close, my $volume) = @$row;

  $code =~ s/\^A//;
  $date =~ s/\//\-/g;

  print "Inserting data for ". $date . " " . $code . " " . $close . "\n";

  my $sth2 = $dbh->prepare("INSERT INTO PriceData.ASX200Price
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

$dbh->disconnect();
$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
