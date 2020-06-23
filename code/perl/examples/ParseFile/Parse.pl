#!/usr/bin/perl

use strict;
use warnings;
 
my $filename = 'AXVIJ.csv';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
my $count = 0;

while (<$fh>){

   my $content = $_;
   my @rows = split(/,/,$content);
   print " --> $rows[0] $rows[1]\n";
}

close ($fh);

