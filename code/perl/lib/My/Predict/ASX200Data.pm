#!/usr/bin/perl;

package ASX200Data;

use DBI;
use Time::Piece;
use Time::Seconds;

use My::Predict::DB;
use My::Predict::Price;


my $singleton;

sub new {
   my $class = shift;
   $singleton ||= bless {}, $class;

   #This is what you normally do:
   #bless $self, $class;
   #return $self;

}

sub getStartDate {
   my $self = shift;

   if (exists $self->{_startDate}) {
   }
   else {
      $self->{_startDate} = "2015-06-24";
   }

   return $self->{_startDate};
}

sub getDateSeries {
   my ($self, $code) = @_; 

   my @dateSeries = ();
   my $dateKey = $self->getStartDate();   
   my $datetime = Time::Piece->strptime($dateKey,"%Y-%m-%d");

   #print "\ngetDateSeries\n";

   if (!exists $self->{$code}) {
      $self->getPriceSeries($code);
   }
   
   while ($dateKey le gmtime->strftime("%Y-%m-%d")) {
   #while ($dateKey le "2015-11-03") {


      #if (!defined $$priceMap{$dateKey}){
      if (!defined $self->{$code}{$dateKey}){
         #print "$dateKey NOT DEFINED\n";
      }
      else{
         #print "$dateKey " . "\n";
         push @dateSeries, $dateKey;
      }

      $datetime = $datetime + ONE_DAY;
      $dateKey =  $datetime->strftime("%Y-%m-%d");
   }
 
   return \@dateSeries;
}


sub getPriceSeries {
   my ($self, $code) = @_;

   #print "\ngetPriceSeries\n";

   if (!exists $self->{$code}) {
     $self->{$code} = {};
     #fetch it from the DB
     #Store as a map of Price obj

     # Open DB connection.
     my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
     ) or die $DBI::errstr;

     my $sth = $dbh->prepare("SELECT * FROM PriceData.ASX200Price WHERE Code = ?");
     $sth->execute($code);

     while (my @row = $sth->fetchrow_array()) {
       my @words = split / /, $row[0];
       my $date = $words[0];

       my $price = new Price($date,$code,$row[2],$row[3],$row[4],$row[5],$row[6],$row[7]);
       $self->{$code}{$date} = $price;
       #$self->{$code}{$date}->print();
     }
     $sth->finish();
   }

   return $self->{$code};
}

sub getCodes {
   my ($self) = @_;

   if (exists $self->{_codes}){
   }
   else {

      $self->{_codes} = [];

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
         push $self->{_codes}, $row[0];
      }
   } 

   return $self->{_codes};
}

sub getClose {
   my ($self, $code, $date) = @_;

   #print "\ngetClosePrice\n";

   my $price = 0;

   if (!exists $self->{$code}) {
     $self->{$code} = {};
     #fetch it from the DB
     #Store as a map of Price obj

     # Open DB connection.
     my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 1 },
     ) or die $DBI::errstr;

     my $sth = $dbh->prepare("SELECT Close FROM PriceData.ASX200Price WHERE Code = ? AND Date = ?");
     $sth->execute($code,$date);

     my @row = $sth->fetchrow_array();
     my @words = split / /, $row[0];
     $price = $words[0];
     $sth->finish();
   }

   return $price;
}




1;
