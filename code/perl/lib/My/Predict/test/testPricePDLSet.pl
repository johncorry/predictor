#!/usr/bin/perl

use strict;
use warnings;

use PDL;

use My::Predict::ASX200Data;
use My::Predict::PricePDLSet;

my $ASX200Data = new ASX200Data();
my $code = "0A?";
my $priceMap_ref = $ASX200Data->getPriceSeries($code);
my $dateSeries_ref = $ASX200Data->getDateSeries($code);

my $pricePDLSet = new PricePDLSet($priceMap_ref, $dateSeries_ref);
print $pricePDLSet->getOpenPDL();
print "\n";
print $pricePDLSet->getScaledOpenPDL();

