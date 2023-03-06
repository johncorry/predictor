#!/usr/bin/perl

# Make sure that when you call this from the cron job that you don't do so on a Sat or Sun as I will insert records for those days.

use strict;
use warnings;
use File::Fetch;
use DBI;
use Time::Piece;
use DateTime;
use Date::Manip;

use My::Predict::DB;

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
my $extractLocation = '/home/ec2-user/data/ASX200/';

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

# Open DB connection.
my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

my $date_obj = new Date::Manip::Date;
$date_obj->parse("Today");
my $end_date = $date_obj->printf('%s');
$date_obj->parse("one month ago");
my $start_date = $date_obj->printf('%s');

my $sth = $dbh->prepare("SELECT Code FROM PriceData.ASX200Company WHERE Sector <> ?");
      $sth->execute("Not Applic");

while (my @row = $sth->fetchrow_array()) {
   
   my $code = $row[0];

   if ($code eq ""){
	next;
   }
  
   print "$code\n";
   my $url = "https://query1.finance.yahoo.com/v7/finance/download/$code.AX?period1=$start_date&period2=$end_date&interval=1d&events=history&includeAdjustedClose=true";

   # Download the archive.
   my $ff = File::Fetch->new(uri => $url);
   #my $file = $ff->fetch( to => $extractLocation ) or die $ff->error;
   my $file = $ff->fetch( to => $extractLocation ) or next;

   #print "file : $file \n";

   open(my $fh, '<:encoding(UTF-8)', $file)
     or die "Could not open file '$file' $!";

   my $count = 0;

   while ( my $line = <$fh>){
     $count = $count + 1;
     #print "$count \n";
     #print "$line \n";

     # Ignore the header.
     if ($count > 1){

       # Tokenise the CSV
       my @values = split(',',$line);

       my $date = $values[0];
       my $open = $values[1];
       my $high = $values[2];
       my $low = $values[3];
       my $close = $values[4];
       my $adjClose = $values[5];
       my $volume = $values[6];
 
       #print "The date of     $code is ". $date ."\n";       
       #print "The open of     $code is ". $open ."\n";
       #print "The high of     $code is ". $high ."\n";
       #print "The low of      $code is ". $low ."\n";
       #print "The vol of      $code is ". $volume ."\n";
       #print "The close of    $code is ". $close ."\n";
       #print "The adjClose of $code is ". $adjClose ."\n";   
       
       print "Inserting data for ". $date . " for ". $code . " " . $close . "\n";
         
       my $sth2 = $dbh->prepare("INSERT INTO ASX200Price
                                (Date,Code,Open,High,Low,Close,Volume,AdjClose) 
                                values 
                                ('$date',
                                 '$code',
                                 '$open',
                                 '$high',
                                 '$low',
                                 '$close',
                                 '$volume',
                                 '$adjClose')
                                ON DUPLICATE KEY UPDATE
                                 Open='$open',
                                 High='$high',
                                 Low='$low',
                                 Close='$close',
                                 Volume='$volume',
                                 AdjClose='$adjClose' 
                              ");

      $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
      $sth2->finish();
     } 
   }
}

$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
