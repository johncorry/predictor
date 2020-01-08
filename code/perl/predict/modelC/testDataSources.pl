#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Time::Piece;
use DateTime;
use Date::Manip;

use My::Predict::DataLookUp;

my $startLogTime = localtime; # scalar context
print "\nExecuting at $startLogTime\n\n";

my $date = new Date::Manip::Date;
$date->parse("1 business days ago");
#$date->parse("Today");
my $date_str = $date->printf("%Y-%m-%d");
print "$date_str\n";

my $ETFLookUp_ref = My::Predict::DataLookUp::create_Daily_ETF_Look_Up();

my @ETFs = ("OOO",   # Oil
            "QAG",   # Agriculture 
            "QCB",   # Broad commodities
            "RCB",   # Bonds
            "QAU",   # Gold
            "QFN",   # Financials
            "QOZ",   # FTSE RAFI Aust 200
            "QUAL",  # MSCI World ex Australian Quality Index
            "NDQ"    # NASDAQ
);

print "Printing ETFs\n";

foreach my $ETF (@ETFs)
{
   print "\t$ETF\t" . $$ETFLookUp_ref{$date_str}->{$ETF} . "\n";
}

print "Done printing ETFs\n\n";

#print "Printing Commodities\n";
#
#my $CommodityLookUp_ref = My::Predict::DataLookUp::create_Daily_Commodity_Look_Up();
#
#my @commodities = ("Oil", "Gold", "Iron");
#
#foreach my $commodity (@commodities)
#{
#   print "$commodity\t" . $$CommodityLookUp_ref{$date_str}->{$commodity} . "\n";
#}
#
#print "Done printing Commodities\n";

print "Printing FX\n";

my $CurrencyLookUp_ref = My::Predict::DataLookUp::create_FXAUD_Look_Up();

my @currencies = ("USD","TWI","CNY","JPY","EUR","GBP","BTC");

foreach my $currency (@currencies)
{
   print "\t$currency\t" . $$CurrencyLookUp_ref{$date_str}->{$currency} . "\n";
}

print "Done printing FX\n\n";

print "Printing BTC\n";

my $BTCLookUp_ref = My::Predict::DataLookUp::create_BTCAUD_Look_Up();

print "\tBTC\t" . $$BTCLookUp_ref{$date_str} . "\n";

print "Done printing BTC\n\n";

my $endLogTime = localtime; # scalar context
my $runTime = $endLogTime - $startLogTime;
print "\nCompleted at $endLogTime\n";
print "Result Runtime $runTime\n";

