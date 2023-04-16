#!/usr/bin/perl

use strict;
use warnings;
use File::Fetch;
use DBI;
use Time::Piece;
use Getopt::Long;
use My::Predict::DB;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

my $rootUrl = "http://www.rba.gov.au/statistics/tables/csv/";
my $filename = "f11.1-data.csv";
my $extractLocation = '/home/jcorry/data/Currency/RBA/';

my $url = $rootUrl . $filename;

# Download the archive.
my $ff = File::Fetch->new(uri => $url);
my $file = $ff->fetch( to => $extractLocation ) or die $ff->error;

print "file : $file \n"; 
 
open(my $fh, '<:encoding(UTF-8)', $file)
  or die "Could not open file '$file' $!";

# Open DB connection.
my $dbh = DBI->connect(     
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();

my $date = "";
my $count = 0;

while ( my $line = <$fh>){
  $count = $count + 1;
  #print "$count \n";

  # Ignore the header.
  if ($count > 11)
  {
    #print "$line \n";
    
    # Tokenise the CSV
    my @values = split(/,/,$line);

    if ($values[0] ne "")
    {
      my $datetime = Time::Piece->strptime($values[0],
                                  "%d-%b-%Y");
  
      $date = $datetime->strftime("%Y-%m-%d 00:00:00");

      print "Inserting data for ". $date . "\n";

      $sth = $dbh->prepare("INSERT INTO FXAUD 
                           (Date, USD, TWI, CNY, JPY, EUR, KRW, GBP, SGD, INR, THB, NZD, TWD, MYR, IDR, VND, AED, PGK, HKD, CAD, ZAR, CHF, PHP, SDR)
                           values 
                           ('$date', 
                            '$values[1]', 
                            '$values[2]', 
                            '$values[3]', 
                            '$values[4]', 
                            '$values[5]', 
                            '$values[6]', 
                            '$values[7]', 
                            '$values[8]', 
                            '$values[9]', 
                            '$values[10]', 
                            '$values[11]', 
                            '$values[12]', 
                            '$values[13]', 
                            '$values[14]', 
                            '$values[15]', 
                            '$values[16]', 
                            '$values[17]', 
                            '$values[18]', 
                            '$values[19]', 
                            '$values[20]', 
                            '$values[21]',
                            '$values[22]', 
                            '$values[23]')");

      $sth->execute();
    }
  }
}
 
$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
