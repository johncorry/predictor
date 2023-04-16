#!/usr/bin/perl

use strict;
use warnings;
use File::Fetch;
use DBI;
use Time::Piece;
use DateTime;
use Date::Manip;
use Finance::Quote; 
#use String::Util qw(trim);

use My::Predict::DB;

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

# Open DB connection.
my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT Code FROM PriceData.ASX200Company WHERE Sector <> ?");
      $sth->execute("Not Applic");

my $q = Finance::Quote->new;

while (my @row = $sth->fetchrow_array()) {
   
   my $code = $row[0];

   if ($code eq ""){
	next;
   }
  
   print "$code\n";

   my %stockinfo = $q->fetch("australia", $code);

   #while ( (my $k, my $v) = each %stockinfo ) {
   #   print "$k => $v\n";
   #}

   
   if (!$stockinfo{$code,"open"}){
        next;
   }

   my $stockdate = trim $stockinfo{$code,"date"};
   my $date_obj = new Date::Manip::Date;
   $date_obj->parse($stockdate);
   my $date = $date_obj->printf('%Y-%m-%d');

   my $open =  trim $stockinfo{$code,"open"};
   my $high =  trim $stockinfo{$code,"high"};
   my $low =  trim $stockinfo{$code,"low"};
   my $close =  trim $stockinfo{$code,"last"};
   my $volume =  trim $stockinfo{$code,"volume"};
 
   #print "The date of $code is ". $date ."\n";
   #print "The close of $code is ". $close ."\n";   
   #print "The open of  $code is ". $open ."\n";
   #print "The high of  $code is ". $high ."\n";
   #print "The low of   $code is ". $low ."\n";
   #print "The vol of   $code is ". $volume ."\n";

   print "Inserting data for ". $date . " for ". $code . " " . $close . "\n";
            
   my $sth2 = $dbh->prepare("INSERT INTO ASX200Price
                             (Date,Code,Open,High,Low,Close,AdjClose,Volume) 
                             values 
                             ('$date',
                              '$code',
                              '$open',
                              '$high',
                              '$low',
                              '$close',
			      0,
                              '$volume')
                             ON DUPLICATE KEY UPDATE
                              Open='$open',
                              High='$high',
                              Low='$low',
                              Close='$close',
                              Volume='$volume' 
                           ");

   $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
   $sth2->finish();

}
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
