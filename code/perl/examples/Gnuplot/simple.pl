#!/usr/bin/perl -w
use strict;
use Chart::Gnuplot;

# Input data source
my @x = (-10 .. 10);
my @y = (0 .. 20);

# Chart object
my $chart = Chart::Gnuplot->new(
    output => "dataSrc_1.jpeg",
);

# Data set object
my $dataSet = Chart::Gnuplot::DataSet->new(
    xdata => \@x,
    ydata => \@y,
);

$chart->plot2d($dataSet);

my $chart2 = Chart::Gnuplot->new(
     output => "animate.gif",
);

my $T = 30; # number of frames
my @c;
for (my $i = 0; $i < $T; $i++)
{
   $c[$i] = Chart::Gnuplot->new(xlabel => 'x');
   my $ds = Chart::Gnuplot::DataSet->new(
         func => "sin($i*2*pi/$T + x)",
   );
   $c[$i]->add2d($ds);
}

$chart2->animate(
    charts => \@c,
    delay  => 10,   # delay 0.1 sec between successive images
);
