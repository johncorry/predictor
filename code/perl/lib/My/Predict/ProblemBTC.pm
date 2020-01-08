package My::Predict::ProblemBTC;

use strict;
use warnings;
#use DateTime;
#use Time::Piece;
use Time::Seconds;
use My::Predict::DataLookUp;
use My::Predict::DataSet;

use base 'Exporter';
our @EXPORT_OK = qw(create_DayDataset create_CurrencyDataset create_CommodityDataset);

my $CommodityLookUp_ref = My::Predict::DataLookUp::create_WB_Commodity_Look_Up();
my $FXAUDLookUp_ref = My::Predict::DataLookUp::create_FXAUD_Look_Up();

sub create_DayDataset {

   my ($startDate) = @_;

   my @dayDataset = (0,0,0,0,0,0,0);
   $dayDataset[$startDate->_wday] = 1;

   #return \@dayDataset;
   return \@dayDataset;

}

sub create_CurrencyDataset {

   my ($currencyKey, $startDate, $lookBackPeriod) = @_;

   my @currencyDataset = ();

   for (my $i=$lookBackPeriod; $i >= 0; $i--) {
      my $datetime = $startDate - ($i * ONE_DAY);

      my $currency = $FXAUDLookUp_ref->{$datetime->strftime("%Y-%m-%d")}->{$currencyKey};

      #print "$currencyKey -> $currency\n";

      push @currencyDataset,$currency;

   }

   #return \@currencyDataset;
   return \@currencyDataset;

}

sub create_CommodityDataset {

   my ($commodityKey, $startDate, $lookBackPeriod) = @_;

   my @commodityDataset = ();

   #print "lookBackPeriod = $lookBackPeriod\n";

   for (my $i=$lookBackPeriod; $i >= 0; $i--) {
      my $datetime = $startDate - ($i * ONE_DAY);

      my $commodity = $CommodityLookUp_ref->{$datetime->strftime("%Y-%m-%d")}->{$commodityKey};

      #print "$commodityKey -> $commodity\n";

      push @commodityDataset, $commodity;

   }

   #return \@commodityDataset;
   return \@commodityDataset;
}

1;
