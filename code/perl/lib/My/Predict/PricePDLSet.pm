#!/usr/bin/perl

package PricePDLSet;
use PDL;

sub new {

   my $class = shift;
   my $priceMap_ref = shift;
   my $dateSeries_ref = shift;

   my @open = ();
   my @high = ();
   my @low = ();
   my @close = ();
   my @volume = ();

   my $prev_open = 0;
   my $prev_high = 0;
   my $prev_low = 0;
   my $prev_close = 0;
   my $prev_volume = 0;


   foreach my $dateKey (@$dateSeries_ref) {

      if (!defined $$priceMap_ref{$dateKey}){
         # Maybe it would better to use the previous price when we don't know.
         #print "NOT DEFINED\n";
         push @open, $prev_open;
         push @high, $prev_high;
         push @low, $prev_low;
         push @close, $prev_close;
         push @volume, $prev_volume;
      }
      else{
         #$$priceMap_ref{$dateKey}->print();
         #print $$priceMap_ref{$dateKey}->getClose() . "\n";
         push @open,   $$priceMap_ref{$dateKey}->getOpen();
         push @high,   $$priceMap_ref{$dateKey}->getHigh();
         push @low,    $$priceMap_ref{$dateKey}->getLow();
         push @close,  $$priceMap_ref{$dateKey}->getClose();
         push @volume, $$priceMap_ref{$dateKey}->getVolume();
         $prev_open = $$priceMap_ref{$dateKey}->getOpen();
         $prev_high = $$priceMap_ref{$dateKey}->getHigh();
         $prev_low = $$priceMap_ref{$dateKey}->getLow();
         $prev_close = $$priceMap_ref{$dateKey}->getClose();
         $prev_volume = $$priceMap_ref{$dateKey}->getVolume();
      }
   }


   my $self = {
     _open_pdl => pdl(@open),
     _low_pdl => pdl(@low),
     _high_pdl => pdl(@high),
     _close_pdl => pdl(@close),
     _volume_pdl => pdl(@volume),
      
   };
   
   my $maxPrice = max($self->{_high_pdl});
 
   if ($maxPrice eq 0){
      $maxPrice = 1;
   }

   $self->{_scaled_open_pdl} = $self->{_open_pdl}/$maxPrice;
   $self->{_scaled_low_pdl} = $self->{_low_pdl}/$maxPrice;
   $self->{_scaled_high_pdl} = $self->{_high_pdl}/$maxPrice;
   $self->{_scaled_close_pdl} = $self->{_close_pdl}/$maxPrice;

   my $maxVolume = max($self->{_volume_pdl});

   if ($maxVolume eq 0){
      $maxVolume = 1;
   }

   $self->{_scaled_volume_pdl} = $self->{_volume_pdl}/$maxVolume;
   
   bless $self, $class;
   return $self;

}

sub getOpenPDL {
   my ( $self ) = @_;
   return $self->{_open_pdl};
}

sub getScaledOpenPDL {
   my ( $self ) = @_;
   return $self->{_scaled_open_pdl};
}

sub getLowPDL {
   my ( $self ) = @_;
   return $self->{_low_pdl};
}

sub getScaledLowPDL {
   my ( $self ) = @_;
   return $self->{_scaled_low_pdl};
}

sub getHighPDL {
   my ( $self ) = @_;
   return $self->{_high_pdl};
}

sub getScaledHighPDL {
   my ( $self ) = @_;
   return $self->{_scaled_high_pdl};
}

sub getClosePDL {
   my ( $self ) = @_;
   return $self->{_close_pdl};
}

sub getScaledClosePDL {
   my ( $self ) = @_;
   return $self->{_scaled_close_pdl};
}

sub getVolumePDL {
   my ( $self ) = @_;
   return $self->{_volume_pdl};
}

sub getScaledVolumePDL {
   my ( $self ) = @_;
   return $self->{_scaled_volume_pdl};
}

1;
