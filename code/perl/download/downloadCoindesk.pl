#!/usr/bin/perl

use strict;
use warnings;
use File::Fetch;
use JSON;
use Data::Dumper;
use DBI;
use Time::Piece;
use Getopt::Long;
use My::Predict::DB;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

my $startDate = ''; # In the form 'YYYY-MM-DD'
my $endDate = ''; 

my $downloadDir = '/home/jcorry/data/BTC/CoinDesk/';

my $result = GetOptions ("start=s" => \$startDate,    
                         "end=s"   => \$endDate,
                         "downloadDir=s"  => \$downloadDir);  # flag


my $url = 'http://api.coindesk.com/v1/bpi/historical/close.json'; 

if ($startDate ne "" && $endDate ne "")
{
   print "start => $startDate" . "\n";
   print "end   => $endDate" . "\n";
   $url = $url . '?start=' . $startDate .'&end=' . $endDate;
}

print "Fetching => $url" . "\n";


# Download the JSON file.
my $ff = File::Fetch->new(uri => $url);
my $filename = $ff->fetch( to => $downloadDir ) or die $ff->error;

# Open the JSON file and create the JSON object.
my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

my $json = JSON->new;
my $data = $json->decode($json_text);

# Open DB connection.
my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0 },
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();

my $date = "";
my $source = "CoinDesk";
my $currency = "USD";
my $price = "";

foreach my $key ( keys %{$data->{'bpi'}} ) {
   $date = "$key 00:00:00";
   $price = ${$data->{'bpi'}}{$key};   
   
   print $price . "\n";

   $sth = $dbh->prepare("INSERT INTO BTCPrice 
                        (Date, Source, Currency, Price )
                        values 
                        ('$date', '$source', '$currency', $price)");

   $sth->execute();
   #$sth->execute() or die $DBI::errstr;

}

$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";


