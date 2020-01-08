#!/usr/bin/perl

use strict;
use warnings;

use PDL::Graphics::PGPLOT;

my $ENV{PGPLOT_XW_WIDTH}=0.3;
dev('/XSERVE');
my $x=sequence(10);
my $y=2*$x**2;
points $x, $y;

