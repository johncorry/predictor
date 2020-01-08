#!/usr/bin/perl

use strict;
use warnings;

use WWW::Mechanize;
use DBI;
use Time::Piece;
use My::Predict::DB;
use Date::Manip;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

my $rootUrl = "https://www.quandl.com/api/v3/datasets/OPEC/ORB.csv?api_key=F5SS-7j_5kBnqn6EsRCX";
my $filename = "OPEC-ORB.csv";
my $extractLocation = '/home/ec2-user/data/Commodity/quandl/';

my $url = $rootUrl;
print $url . "\n";

my $mech = WWW::Mechanize->new();
$mech->get( $url );
$mech->save_content("$extractLocation$filename");
#exit;

my $file = $extractLocation . $filename;
print "file : $file \n"; 
#exit;
 
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

my $count = 0;

while ( my $line = <$fh>){
  $count = $count + 1;
  #print "$count \n";

  # Ignore the header.
  if ($count > 1)
  {
    #print "$line \n";
    
    # Tokenise the CSV
    my @values = split(/,/,$line);

    if ($values[0] ne "")
    {


      my $date = new Date::Manip::Date;
      print "-> " . $values[0] . "\n";
      $date->parse($values[0]);

      # We are shifting the date forward by a business day as the value is recorded daily 
      # but it is dated a day behind. 
      $date->next_business_day(1);
      my $date_str = $date->printf("%Y-%m-%d");
      print "Inserting data for ". $date_str . " - " . $values[1] . "\n";

      $sth = $dbh->prepare("INSERT INTO OpecCrudeOil
                           (Date, Value)
                           values 
                           ('$date_str',
                            '$values[1]')");

      $sth->execute();
          # or die "Can't execute: ", $dbh->errstr;
    }
  }
}
 
$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
