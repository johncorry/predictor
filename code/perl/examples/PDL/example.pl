#!/usr/bin/perl

use strict;
use warnings;
use PDL;

use Time::Piece;
use Time::Seconds;
use My::Predict::DB;
use My::Predict::Chart;
use My::Predict::DataLookUp;
use My::Predict::DataSet;
use My::Predict::Problem;
#use Algorithm::SVM;
#use Algorithm::SVM::DataSet;
use DateTime;
#use Getopt::Long;

my @CURRENCYKEYS = ('USD','GBP','JPY','TWI');
my $FXAUDLookUp_ref = My::Predict::DataLookUp::create_FXAUD_Look_Up();

sub create_CurrencyDataset {

   my ($currencyKey, $startDate, $lookBackPeriod) = @_;

   my @currencyDataset = ();

   for (my $i=$lookBackPeriod; $i >= 0; $i--) {
      my $datetime = $startDate - ($i * ONE_DAY);

      my $currency = $FXAUDLookUp_ref->{$datetime->strftime("%Y-%m-%d")}->{$currencyKey};

      #print "$currencyKey -> $currency\n";
      
      push @currencyDataset,$currency;
      
   }
      
   return \@currencyDataset;
}      

my $dateKey = "2015-04-22";
my $startDate = Time::Piece->strptime($dateKey, "%Y-%m-%d");
my $a = pdl create_CurrencyDataset("USD", $startDate, 20);      

print "$a\n";

my $b = sqrt($a);
print "$b\n";

my $c = where($a, $a > 5);
print "$c\n";

