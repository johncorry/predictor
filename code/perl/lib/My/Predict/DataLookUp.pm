package My::Predict::DataLookUp;

use strict;
use warnings;

use DBI;
use Time::Piece;
use Time::Seconds;

use My::Predict::DB;

use base 'Exporter';
our @EXPORT_OK = qw(create_Daily_ETF_Look_Up create_Daily_Commodity_Look_Up create_WB_Commodity_Look_Up create_FXAUD_Look_Up create_BTCAUD_Look_Up create_ASX200_Look_Up);

our $EARLIEST_BTC_PRICE = "2010-07-18";
our $EARLIEST_ASX_PRICE = "2015-06-24";

sub create_Daily_ETF_Look_Up{

  # Open DB connection.
   my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $ETFLookUp_ref = {};
   my $lastDate;

   my @codes = ("OOO",   # Oil
                "QAG",   # Agriculture 
                "QCB",   # Broad commodities
                "RCB",   # Bonds
                "QAU",   # Gold
                "QFN",   # Financials
                "QOZ",   # FTSE RAFI Aust 200
                "QUAL",  # MSCI World ex Australian Quality Index
                "NDQ"    # NASDAQ
               );


   foreach my $code (@codes)
   {
      #print "$code\n";
      my $sth = $dbh->prepare("SELECT Date, Close FROM PriceData.ASXETF WHERE Code = ?");

      $sth->execute($code);
      my $ETF_ref = $sth->fetchall_arrayref();

      foreach my $row(@$ETF_ref) {
         my ($Date, $Price) = @$row;

         #print "$code $Date $Price\n";
         my $datetime = Time::Piece->strptime($Date,
                                              "%Y-%m-%d %H:%M:%S");

         my $dateKey =  $datetime->strftime("%Y-%m-%d");

         #print $dateKey ." -> " . $Price . "\n"; 
         if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
            $ETFLookUp_ref->{$dateKey}->{$code} = $Price;
            $lastDate = $datetime;
            #print $dateKey ." ->> " . $Price . "\n";
            #print $ETFLookUp_ref->{$dateKey}->{$code} . "\n";
         }
         else {
            my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;
            #print " -> $numDaysDiff\n";
            # Need to apply a linear interpolation here.
            for (my $d = 1; $d <= $numDaysDiff; $d++){
               my $dateKeyItr = ($lastDate + (ONE_DAY * $d))->strftime("%Y-%m-%d");
               #print " -> $dateKeyItr => $Price\n";
               $ETFLookUp_ref->{$dateKeyItr}->{$code} = $Price;
            }
            $lastDate = $datetime;
         }
      }

      $sth->finish();
   }

   $dbh->disconnect();

   return $ETFLookUp_ref;
}


sub create_Daily_Commodity_Look_Up{

  # Open DB connection.
   my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Date, Value FROM OpecCrudeOil");
   $sth->execute();
   my $Commodity_ref = $sth->fetchall_arrayref();

   my $CommodityLookUp_ref = {};
   my $lastDate;

   my $CurrencyLookUp_ref = create_FXAUD_Look_Up(); 

   foreach my $row(@$Commodity_ref) {
      my ($Date, $Value) = @$row;

      my $datetime = Time::Piece->strptime($Date,
                                           "%Y-%m-%d %H:%M:%S");

      my $dateKey =  $datetime->strftime("%Y-%m-%d");
   
      # Need to convert to AUD but there maybe more Oil data than 
      # FX data so check.
      if (defined $$CurrencyLookUp_ref{$dateKey}->{USD}){
         $Value = $Value / $$CurrencyLookUp_ref{$dateKey}->{USD};

         #print $dateKey ." -> " . $Value . "\n"; 
         if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
            $CommodityLookUp_ref->{$dateKey}->{Oil} = $Value;
            $lastDate = $datetime;
            #print $dateKey ." ->> " . $Value . "\n";
            #print $CommodityLookUp_ref->{$dateKey}->{Oil} . "\n";
         }
         else {
            my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;
            #print " -> $numDaysDiff\n";
            # Need to apply a linear interpolation here.
            for (my $d = 1; $d <= $numDaysDiff; $d++){
               my $dateKeyItr = ($lastDate + (ONE_DAY * $d))->strftime("%Y-%m-%d");
               #print " -> $dateKeyItr\n";
               $CommodityLookUp_ref->{$dateKeyItr}->{Oil} = $Value;
            }
         $lastDate = $datetime;
         }
      }
   }

   $sth = $dbh->prepare("SELECT Date, Close FROM ASX200Price WHERE Code = 'GOLD'");
   $sth->execute();
   $Commodity_ref = $sth->fetchall_arrayref();

   foreach my $row(@$Commodity_ref) {
      my ($Date, $Price) = @$row;

      $Price = $Price * 10; # This value is based on an ETF which is priced at a 10th.
      my $datetime = Time::Piece->strptime($Date,
                                           "%Y-%m-%d %H:%M:%S");

      my $dateKey =  $datetime->strftime("%Y-%m-%d");

      #print $dateKey ." -> " . $Price . "\n"; 
      if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
         $CommodityLookUp_ref->{$dateKey}->{Gold} = $Price;
         $lastDate = $datetime;
         #print $dateKey ." ->> " . $Price . "\n";
         #print $CommodityLookUp_ref->{$dateKey}->{Gold} . "\n";
      }
      else {
         my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;
         #print " -> $numDaysDiff\n";
         # Need to apply a linear interpolation here.
         for (my $d = 1; $d <= $numDaysDiff; $d++){
            my $dateKeyItr = ($lastDate + (ONE_DAY * $d))->strftime("%Y-%m-%d");
            #print " -> $dateKeyItr => $Price\n";
            $CommodityLookUp_ref->{$dateKeyItr}->{Gold} = $Price;
         }
        $lastDate = $datetime;
      }
   }

   $sth = $dbh->prepare("SELECT Date, Value FROM IronOreChina");
   $sth->execute();
   $Commodity_ref = $sth->fetchall_arrayref();

   foreach my $row(@$Commodity_ref) {
      my ($Date, $Value) = @$row;

      my $datetime = Time::Piece->strptime($Date,
                                           "%Y-%m-%d %H:%M:%S");

      my $dateKey =  $datetime->strftime("%Y-%m-%d");

      # Need to convert to AUD but there maybe more Oil data than 
      # FX data so check.
      if (defined $$CurrencyLookUp_ref{$dateKey}->{USD}){
         $Value = $Value / $$CurrencyLookUp_ref{$dateKey}->{USD};
         

         #print $dateKey ." -> " . $Value . "\n"; 
         if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
            $CommodityLookUp_ref->{$dateKey}->{Iron} = $Value;
            $lastDate = $datetime;
            #print $dateKey ." ->> " . $Value . "\n";
            #print $CommodityLookUp_ref->{$dateKey}->{Iron} . "\n";
         }
         else {
            my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;
            #print " -> $numDaysDiff\n";
            # Need to apply a linear interpolation here.
            for (my $d = 1; $d <= $numDaysDiff; $d++){
               my $dateKeyItr = ($lastDate + (ONE_DAY * $d))->strftime("%Y-%m-%d");
               #print " -> $dateKeyItr\n";
               $CommodityLookUp_ref->{$dateKeyItr}->{Iron} = $Value;
            }
         $lastDate = $datetime;
         }
      }
   }


   $sth->finish();
   $dbh->disconnect();

   return $CommodityLookUp_ref;
}

sub create_WB_Commodity_Look_Up{

   # Open DB connection.
   my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Date, Oil, Coal, NaturalGas, Rice, Wheat, Beef, Chicken, Sugar, Iron, Copper, Gold, Silver FROM Commodities");
   $sth->execute();
   my $Commodity_ref = $sth->fetchall_arrayref();
   $sth->finish();
   $dbh->disconnect();

   my $CommodityLookUp_ref = {};
   my $lastDate;

   foreach my $row(@$Commodity_ref) {
      my ($Date, $Oil, $Coal, $NaturalGas, $Rice, $Wheat, $Beef, $Chicken, $Sugar, $Iron, $Copper, $Gold, $Silver) = @$row;

      my $datetime = Time::Piece->strptime($Date,
                                           "%Y-%m-%d %H:%M:%S");

      my $dateKey =  $datetime->strftime("%Y-%m-%d");

      if (defined $lastDate){
         my $tempdate = ($datetime - $lastDate)/ONE_DAY;

      }

      if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
         $CommodityLookUp_ref->{$dateKey}->{Oil} = $Oil;
         $CommodityLookUp_ref->{$dateKey}->{Coal} = $Coal;
         $CommodityLookUp_ref->{$dateKey}->{NaturalGas} = $NaturalGas;
         $CommodityLookUp_ref->{$dateKey}->{Rice} = $Rice;
         $CommodityLookUp_ref->{$dateKey}->{Wheat} = $Wheat;
         $CommodityLookUp_ref->{$dateKey}->{Beef} = $Beef;
         $CommodityLookUp_ref->{$dateKey}->{Chicken} = $Chicken;
         $CommodityLookUp_ref->{$dateKey}->{Sugar} = $Sugar;
         $CommodityLookUp_ref->{$dateKey}->{Iron} = $Iron;
         $CommodityLookUp_ref->{$dateKey}->{Copper} = $Copper;
         $CommodityLookUp_ref->{$dateKey}->{Gold} = $Gold;
         $CommodityLookUp_ref->{$dateKey}->{Silver} = $Silver;
         $lastDate = $datetime;
      }
      else {
         my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;

         for (my $day = 1; $day <= $numDaysDiff; $day++){
            my $dateKeyItr = ($lastDate + (ONE_DAY * $day))->strftime("%Y-%m-%d");

            my $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Oil};
            $CommodityLookUp_ref->{$dateKeyItr}->{Oil} = $lastPrice + ($day * (($Oil - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Coal};
            $CommodityLookUp_ref->{$dateKeyItr}->{Coal} = $lastPrice + ($day * (($Coal - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{NaturalGas};
            $CommodityLookUp_ref->{$dateKeyItr}->{NaturalGas} = $lastPrice + ($day * (($NaturalGas - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Rice};
            $CommodityLookUp_ref->{$dateKeyItr}->{Rice} = $lastPrice + ($day * (($Rice - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Wheat};
            $CommodityLookUp_ref->{$dateKeyItr}->{Wheat} = $lastPrice + ($day * (($Wheat - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Beef};
            $CommodityLookUp_ref->{$dateKeyItr}->{Beef} = $lastPrice + ($day * (($Beef - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Chicken};
            $CommodityLookUp_ref->{$dateKeyItr}->{Chicken} = $lastPrice + ($day * (($Chicken - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Sugar};
            $CommodityLookUp_ref->{$dateKeyItr}->{Sugar} = $lastPrice + ($day * (($Sugar - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Iron};
            $CommodityLookUp_ref->{$dateKeyItr}->{Iron} = $lastPrice + ($day * (($Iron - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Copper};
            $CommodityLookUp_ref->{$dateKeyItr}->{Copper} = $lastPrice + ($day * (($Copper - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Gold};
            $CommodityLookUp_ref->{$dateKeyItr}->{Gold} = $lastPrice + ($day * (($Gold - $lastPrice)/$numDaysDiff));

            $lastPrice = $CommodityLookUp_ref->{$lastDate->strftime("%Y-%m-%d")}->{Silver};
            $CommodityLookUp_ref->{$dateKeyItr}->{Silver} = $lastPrice + ($day * (($Silver - $lastPrice)/$numDaysDiff));

         }
        $lastDate = $datetime;
      }

   }

   while ($lastDate < gmtime ){
      my $dateKeyItrPrev = $lastDate->strftime("%Y-%m-%d");
      $lastDate = $lastDate + ONE_DAY;
      my $dateKeyItr = $lastDate->strftime("%Y-%m-%d");
      $CommodityLookUp_ref->{$dateKeyItr}->{Oil} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Oil};
      $CommodityLookUp_ref->{$dateKeyItr}->{Coal} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Coal};
      $CommodityLookUp_ref->{$dateKeyItr}->{NaturalGas} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{NaturalGas};
      $CommodityLookUp_ref->{$dateKeyItr}->{Rice} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Rice};
      $CommodityLookUp_ref->{$dateKeyItr}->{Wheat} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Wheat};
      $CommodityLookUp_ref->{$dateKeyItr}->{Beef} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Beef};
      $CommodityLookUp_ref->{$dateKeyItr}->{Chicken} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Chicken};
      $CommodityLookUp_ref->{$dateKeyItr}->{Sugar} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Sugar};
      $CommodityLookUp_ref->{$dateKeyItr}->{Iron} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Iron};
      $CommodityLookUp_ref->{$dateKeyItr}->{Copper} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Copper};
      $CommodityLookUp_ref->{$dateKeyItr}->{Gold} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Gold};
      $CommodityLookUp_ref->{$dateKeyItr}->{Silver} = $CommodityLookUp_ref->{$dateKeyItrPrev}->{Silver};
   }

   return $CommodityLookUp_ref;
}

sub create_FXAUD_Look_Up{

   # Open DB connection.
   my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Date, USD, TWI, CNY, JPY, EUR, GBP FROM FXAUD");
   $sth->execute();
   my $FXAUD_ref = $sth->fetchall_arrayref();
   $sth->finish();

   my $FXAUDLookUp_ref = {};
   my $lastDate;

   foreach my $row(@$FXAUD_ref) {
      my ($Date, $USD, $TWI, $CNY, $JPY, $EUR, $GBP) = @$row;
      #print "$Date\n";
      
      # Scale the currencies to help the SVM.
      #$JPY = $JPY/100;
      #$CNY = $CNY/10;
      #$TWI = $TWI/100;
      #$GBP = $GBP/100;

      my $datetime = Time::Piece->strptime($Date,
                                           "%Y-%m-%d %H:%M:%S");

      my $dateKey =  $datetime->strftime("%Y-%m-%d");

      if (defined $lastDate){
         my $tempdate = ($datetime - $lastDate)/ONE_DAY;
         #print "tempDate = $tempdate\n";
      }

      if ((!defined $lastDate) or (($datetime - $lastDate)/ONE_DAY) == 1) {
         #print "Datekey $dateKey -> 1\n";
         $FXAUDLookUp_ref->{$dateKey}->{USD} = $USD;
         $FXAUDLookUp_ref->{$dateKey}->{TWI} = $TWI;
         $FXAUDLookUp_ref->{$dateKey}->{CNY} = $CNY;
         $FXAUDLookUp_ref->{$dateKey}->{JPY} = $JPY;
         $FXAUDLookUp_ref->{$dateKey}->{EUR} = $EUR;
         $FXAUDLookUp_ref->{$dateKey}->{GBP} = $GBP;
         $lastDate = $datetime;
      }
      else {
         my $numDaysDiff = ($datetime - $lastDate)/ONE_DAY;
         #print " -> $numDaysDiff\n";
         # Need to apply a linear interpolation here.
         for (my $d = 1; $d <= $numDaysDiff; $d++){
            my $dateKeyItr = ($lastDate + (ONE_DAY * $d))->strftime("%Y-%m-%d");
            #print " -> $dateKeyItr\n";
            $FXAUDLookUp_ref->{$dateKeyItr}->{USD} = $USD;
            $FXAUDLookUp_ref->{$dateKeyItr}->{TWI} = $TWI;
            $FXAUDLookUp_ref->{$dateKeyItr}->{CNY} = $CNY;
            $FXAUDLookUp_ref->{$dateKeyItr}->{JPY} = $JPY;
            $FXAUDLookUp_ref->{$dateKeyItr}->{EUR} = $EUR;
            $FXAUDLookUp_ref->{$dateKeyItr}->{GBP} = $GBP;
         }
        $lastDate = $datetime;
      }

   }

   my $sth2 = $dbh->prepare("SELECT Date, Currency, Price FROM BTCPrice");
   $sth2->execute();
   my $allBTCPricesInUSD = $sth2->fetchall_arrayref();

   my $USD = 0;
   my $AUDBTC = 0;

   foreach my $row (@$allBTCPricesInUSD) {
      my ($RawDateTime, $Currency, $Price) = @$row;

      #FIXME This is a hack.  The BitCoin day is off by a day.
      #my $datetime = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S"); 
      my $datetime1 = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S");
      #print "\ndatetime orig : $datetime1\n";
      my $datetime = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S") + 86400;
      #print "datetime mod  : $datetime\n";

      my $dateKey =  $datetime->strftime("%Y-%m-%d");

      if (defined $FXAUDLookUp_ref->{$dateKey}->{USD}){
         $USD = $FXAUDLookUp_ref->{$dateKey}->{USD};
      }

      $AUDBTC = $Price/$USD;
      $FXAUDLookUp_ref->{$dateKey}->{BTC} = $AUDBTC;
      #print "Result $dateKey = $AUDBTC \n";
   }

   $sth2->finish();
   $dbh->disconnect();   

   return $FXAUDLookUp_ref;
}

sub create_BTCAUD_Look_Up{

   # Open DB connection.
      my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Date, Currency, Price FROM BTCPrice");
   $sth->execute();
   my $allBTCPricesInUSD = $sth->fetchall_arrayref();
   $sth->finish();
   $dbh->disconnect();

   my $FXAUDLookUp_ref = My::Predict::DataLookUp::create_FXAUD_Look_Up();

   my $USD = 0;
   my $AUDBTC = 0;
   my $BTCAUDLookUp_ref = {};

   foreach my $row (@$allBTCPricesInUSD) {
      my ($RawDateTime, $Currency, $Price) = @$row;

      #FIXME This is a hack.  The BitCoin day is off by a day.
      #my $datetime = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S"); 
      my $datetime1 = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S");
      #print "\ndatetime orig : $datetime1\n";
      my $datetime = Time::Piece->strptime($RawDateTime, "%Y-%m-%d %H:%M:%S") + 86400;
      #print "datetime mod  : $datetime\n";

      my $date =  $datetime->strftime("%Y-%m-%d");

      if (defined $FXAUDLookUp_ref->{$date}->{USD}){
         $USD = $FXAUDLookUp_ref->{$date}->{USD};
      }

      $AUDBTC = $Price/$USD;
      $BTCAUDLookUp_ref->{$date} = $AUDBTC;
   }

   #Finally add a price for today if we don't have one.
   if (!defined $BTCAUDLookUp_ref->{gmtime()->strftime("%Y-%m-%d")}){
      print "Warning No BTC Price for today.\n";
      #FIXME Need to fetch price.
      #$BTCAUDLookUp_ref->{gmtime()->strftime("%Y-%m-%d")} = $TODAYS_BTC_PRICE;
   }
   else {
      my $Todays_BTC_Price = $BTCAUDLookUp_ref->{gmtime()->strftime("%Y-%m-%d")};
      #print "Today's BTC Price : $Todays_BTC_Price \n";
   }

   #Finally add a price for yesterday if we don't have one.
   if (!defined $BTCAUDLookUp_ref->{(gmtime() - ONE_DAY)->strftime("%Y-%m-%d")}){
      print "Warning No BTC Price for yesterday.\n";
      #FIXME Need to fetch price.
      #$BTCAUDLookUp_ref->{(gmtime() - ONE_DAY)->strftime("%Y-%m-%d")} = $YESTERDAYS_BTC_PRICE;
   }
      
   return $BTCAUDLookUp_ref;
}


sub create_ASX200_Company_List{

   # Open DB connection.
      my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Code FROM PriceData.ASX200Company WHERE Sector <> ?");
   $sth->execute("Not Applic");

   while (my @row = $sth->fetchrow_array()) {

      my $Code = $row[0];

   }
}


sub create_ASX200_Look_Up{

   # Open DB connection.
      my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT Code FROM PriceData.ASX200Company WHERE Sector <> ?");
   $sth->execute("Not Applic");

   while (my @row = $sth->fetchrow_array()) {

      my $Code = $row[0];

      my $sth2 = $dbh->prepare("SELECT * FROM PriceData.ASX200Price WHERE Code = ?");

      $sth2->execute($Code);

      while (my @row = $sth2->fetchrow_array()) {
         
         my $Date = $row[0];
         my $Open = $row[2];
         my $High = $row[3];
         my $Low = $row[4];
         my $Close = $row[5];
         my $Volume = $row[6];
         my $AdjClose = $row[7];
      }
      $sth2->finish();
   }

   #return $FXAUDLookUp_ref;
}



1;
