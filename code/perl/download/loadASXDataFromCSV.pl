#!/usr/bin/perl

use strict;
use warnings;

use WWW::Mechanize;
use DBI;
use Time::Piece;
use Getopt::Long;
use My::Predict::DB;
use DateTime;
use Date::Manip;
use Number::Bytes::Human qw(format_bytes);

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

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();
$sth->finish();

sub loadPriceData {

   my ( $file, $code ) = @_;

   print "code,date,open,low,high,close,volume,PE\n";

   #print "file : $file \n";
   #exit;

   my $open = 0;
   my $close = 0;
   my $date = "";
   my $PE = 0;
   my $high = 0;
   my $low = 0;
   my $volume = 0;

   open(my $fh, '<:encoding(UTF-8)', "$file")
      or die "Could not open file $file\n $!";
 
   my $count = 0;

   while ( my $line = <$fh>)
   {
      $count = $count + 1;
      print "$count \n";
      print " -> $line";

      # Tokenise the CSV
      my @values = split(/,/,$line);

      if ($count < 2)
      {
         print "Skipping line\n";
      }
      elsif ($values[0] ne "")
      {
         my $line_date = new Date::Manip::Date;
         $values[0] =~ s/\"//g;
         $values[1] =~ s/\"//g; 
         #print " -> $values[0] $values[1]\n";
         my $date_str = "$values[0] $values[1]";
         #print " -->$date_str\n";
         $line_date->parse($date_str);
         #print "$days " . $file_date->printf("%Y%m%d") . "\n";
         $date = $line_date->printf("%Y%m%d");

         $close = $values[2];
         $open = $values[3];
         $high = $values[4];
         $low = $values[5];

         print "$code,$date,$open,$low,$high,$close,$volume,$PE\n";

         print "Inserting data for ". $date . " for ". $code . " " . $open . "\n";
         #exit;

         my $sth2 = $dbh->prepare("INSERT INTO ASX200Price
                                   (Date,Code,Open,High,Low,Close,Volume,PE) 
                                   values 
                                   ('$date',
                                    '$code',
                                    '$open',
                                    '$high',
                                    '$low',
                                    '$close',
                                    '$volume',
                                    '$PE')
                                   ON DUPLICATE KEY UPDATE
                                    Open='$open',
                                    High='$high',
                                    Low='$low',
                                    Close='$close',
                                    Volume='$volume',
                                    PE='$PE' 
                                  ");

         $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
         $sth2->finish();
      }
   }
   $fh->close();
   unlink $file;
}

loadPriceData("xvi.csv","XVI");

$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
