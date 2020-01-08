#!/usr/bin/perl;

package ASXIndicesData;

use DBI;
use Time::Piece;
use Time::Seconds;

use My::Predict::DB;
use My::Predict::Price;


my $singleton;

my %indexLookUp = ('Automobiles & Components','XNJ',
                   'Banks','XFJ',
                   'Capital Goods','XNJ',
                   'Class Pend',"NONE",
                   'Commercial Services & Supplies','XNJ',
                   'Consumer Durables & Apparel','XSJ',
                   'Consumer Services','XSJ',
                   'Diversified Financials','XFJ',
                   'Energy','XEJ',
                   'Food & Staples Retailing','XSJ',
                   'Food, Beverage & Tobacco','XSJ',
                   'Health Care Equipment & Services','XHJ',
                   'Household & Personal Products','XSJ',
                   'Insurance','XFJ',
                   'Materials','XMJ',
                   'Media','XSJ',
                   'Not Applic','NONE',
                   'Pharmaceuticals & Biotechnology','XHJ',
                   'Real Estate','XPJ',
                   'Retailing','XSJ',
                   'Semiconductors & Semiconductor Equipment','XIJ',
                   'Software & Services','XIJ',
                   'Technology Hardware & Equipment','XIJ',
                   'Telecommunication Services','XTJ',
                   'Transportation','XNJ',
                   'Utilities','XUJ'
);

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
      $self->{_startDate} = "2015-03-04";
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
   
   while ($dateKey ne gmtime->strftime("%Y-%m-%d")) {

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

sub getIndexCode {
   my ($self, $code) = @_;

   #print "\ngetIndexCode\n";

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

     my $sth = $dbh->prepare("SELECT * FROM PriceData.ASX200Company WHERE Code = ?");
     $sth->execute($code);

     my @row = $sth->fetchrow_array();
     $sth->finish();
 
     my @words = split / /, $row[0];
     my $name = $row[1];
     my $sector = $row[2];
     #print "$code $name $sector \n";
     # Need to check this as it might return nothing so we should replace it with "NONE".
     if (!exists $indexLookUp{$sector}){
        $self->{$code} = "NONE";
     }
     else {
        $self->{$code} = $indexLookUp{$sector};
     }
   }

   return $self->{$code};
}

sub getIndexSeries {
   my ($self, $code) = @_;

   #print "\ngetIndexSeries\n";

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

     # 5/1/18 Removed to use ASX200Price table instead.
     # my $sth = $dbh->prepare("SELECT * FROM PriceData.ASXIndicesPrice WHERE Code = ?");
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

1;
