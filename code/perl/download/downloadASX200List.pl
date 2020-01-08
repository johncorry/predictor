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
my $extractLocation = '/home/ec2-user/data/ASX200/';

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
    #print "$line \n";
    
    # Tokenise the CSV
    my @values = split(/"/,$line);

    #print "\n\n";
    #print "Size = @values\n";

    chop($values[2]);
    my $temp = reverse($values[2]);
    chop($temp);
    $values[2] = reverse($temp);

    #print "$values[1]\n";
    #print "$values[2]\n";
    #print "$values[3]\n";

    $sth = $dbh->prepare("INSERT INTO ASX200Company
                         (Code,Name,Sector) 
                         values 
                         ('$values[2]', 
                          '$values[1]', 
                          '$values[3]')");
    $sth->execute();
  }
}
 
$sth->finish();
$dbh->disconnect();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
