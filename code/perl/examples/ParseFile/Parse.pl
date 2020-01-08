#!/usr/bin/perl

use strict;
use warnings;
 
my $filename = '2010-2013.csv';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
my $count = 0;

my $content = <$fh>;
my @rows = split(/\r/,$content);

foreach (@rows)
{
  print "$_\n";
}

