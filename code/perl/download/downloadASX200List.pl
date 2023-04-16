#!/usr/bin/perl
# Downloads a list of all the companies that make up the ASX200.
# The list is obtained from the ASX.

use strict;
use warnings;
use File::Fetch;
use DBI;
use Time::Piece;
use Getopt::Long;
use My::Predict::DB;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";
my $rootUrl = "http://www.asx.com.au/asx/research/";
my $filename = "ASXListedCompanies.csv";
my $extractLocation = '/home/jcorry/data/ASX200/';

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

my $count = 0;

while ( my $line = <$fh>){
  $count = $count + 1;
  #print "$count \n";

  # Ignore the header.
  if ($count > 3)
  {
    #print "\n$line \n";
    
    # Tokenise the CSV
    my @values = split(/\,/,$line);

    #print "\n0 -> " . "$values[0]\n";
    #print "1 -> " . "$values[1]\n";
    #print "2 -> " . "$values[2]\n";

    my $name = $values[0];
    $name =~ s/\'//g; # remove any single quotes
    $name =~ s/\"//g;
    my $code = $values[1];
    $code =~ s/\"//g;
    my $sector = $values[2];
    $sector =~ s/\"//g;

    #print "Code   " . $code . "\n";
    #print "Name   " . $name . "\n"; 
    #print "Sector " . $sector . "\n";

    $sth = $dbh->prepare("INSERT INTO ASX200Company
                         (Code,Name,Sector)
                          values
                          ('$code',
                           '$name',
                           '$sector')
                          ON DUPLICATE KEY UPDATE
                          Name = '$name',
                          Sector = '$sector'");

    $sth->execute()
      or die "Error inserting record: " . $dbh->errstr;
  }
}
 
$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
