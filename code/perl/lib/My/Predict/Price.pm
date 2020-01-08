#!/usr/bin/perl

package Price;

sub new
{
   my $class = shift;
   my $self = {
      _date     => shift,
      _code     => shift,
      _open     => shift,
      _high     => shift,
      _low      => shift,
      _close    => shift,
      _volume   => shift,
      _adjClose => shift,
   };

   bless $self, $class;
   return $self;
}

sub prettyPrint {
   my ( $self ) = @_;

   print "Date     : $self->{_date}\n";
   print "Code     : $self->{_code}\n";
   print "Open     : $self->{_open}\n";
   print "High     : $self->{_high}\n";
   print "Low      : $self->{_low}\n";
   print "Close    : $self->{_close}\n";
   print "Volume   : $self->{_volume}\n";
   print "AdjClose : $self->{_adjClose}\n";
}

sub print {
   my ( $self ) = @_;

   print "$self->{_date},";
   print "$self->{_code},";
   print "$self->{_open},";
   print "$self->{_high},";
   print "$self->{_low},";
   print "$self->{_close},";
   print "$self->{_volume},";
   print "$self->{_adjClose}\n";
}

sub getDate {   
   my ( $self ) = @_;
   return $self->{_date};
}

sub getCode {
   my ( $self ) = @_;
   return $self->{_code};
}
sub getOpen {
   my ( $self ) = @_;
   return $self->{_open};
}

sub getHigh {
   my ( $self ) = @_;
   return $self->{_high};
}

sub getLow {
   my ( $self ) = @_;
   return $self->{_low};
}

sub getClose {
   my ( $self ) = @_;
   return $self->{_close};
}

sub getVolume {
   my ( $self ) = @_;
   return $self->{_volume};
}

sub getAdjClose {
   my ( $self ) = @_;
   return $self->{_adjClose};
}

1;
