#!/usr/bin/perl

use strict;
use warnings;

use My::Predict::Price;

my $obj1 = new Price("22-04-1976","JDC",1,2,3,4,5,6);
my $code = $obj1->getCode();
print "$code\n";
$obj1->print();
$obj1->prettyPrint();

