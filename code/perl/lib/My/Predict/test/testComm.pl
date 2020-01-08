#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Time::Piece;

use My::Predict::DataLookUp;


my $CommodityLookUp_ref = My::Predict::DataLookUp::create_Daily_Commodity_Look_Up();

print "Test Oil  -> " . $$CommodityLookUp_ref{"2017-06-09"}->{Oil} . "\n";
print "Test Gold -> " . $$CommodityLookUp_ref{"2017-06-09"}->{Gold} . "\n";
print "Test Iron -> " . $$CommodityLookUp_ref{"2017-06-09"}->{Iron} . "\n";
#$self->{_FXAUDMap}{$dateKey}->{$currancyKey};
