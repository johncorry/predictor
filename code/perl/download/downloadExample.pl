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

my $start_date = new Date::Manip::Date;
$start_date->parse("last Saturday");
my $start_date_str = $start_date->printf("%Y%m%d");

my $baseurl = "http://www.asxhistoricaldata.com/wp-content/uploads/week";

print $baseurl . $start_date_str . ".zip\n";
