#!/usr/bin/perl

use strict;
use DBI;
use Time::Piece;

my $dbh = DBI->connect(          
    "dbi:mysql:PriceData:datastore.c6lgnooprssz.ap-southeast-2.rds.amazonaws.com",
    "jcorry",                          
    "iona22",                          
    { RaiseError => 1 },         
) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT VERSION()");
$sth->execute();

my $ver = $sth->fetch();

print @$ver;
print "\n";

#my $date = Time::Piece->strptime('12/22/13 21:48:06', '%D %T');
#print $date->strftime('%F %T');

my $date = "2014-12-22 01:02:34";
my $source = "Bob";
my $currency = "USD";
my $price = 2.02;

$sth = $dbh->prepare("INSERT INTO BTCPrice 
                     (Date, Source, Currency, Price )
                     values
                     ('$date', '$source', '$currency', $price)");

$sth->execute() or die $DBI::errstr;
$sth->finish();
$dbh->disconnect();
