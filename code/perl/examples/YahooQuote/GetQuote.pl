#!/usr/bin/perl
use strict;
use warnings;

use Finance::YahooQuote;

my @symbols = ("IBM", "BTCUSD=X", "BTCAUD=X", "XAUAUD=X");
#my @columns = ("Last Trade (Price Only)","Last Trade Date","Last Trade Time","Day's Range","52-week Range","EPS Est. Next Year","P/E Ratio","PEG Ratio","Dividend Yield");
my @columns = ("Last Trade (Price Only)","Last Trade Date","Last Trade Time");

my $arrptr = getcustomquote(\@symbols, \@columns);

my $i = 0;

foreach my $symbol (@symbols){

  my @quotes = @{$arrptr->[$i++]};
  print "$symbol\t@quotes\n";
        
}

