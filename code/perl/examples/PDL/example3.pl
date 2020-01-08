#!/usr/bin/perl

use PDL;

$a = pdl [[1,2],
          [2,3],
          [3,4],
          [4,5]];

$c = pdl [[1,0,1.0,0.5],
          [0,1,0.5,0.5]];

print "a = ";
print $a;

#$b = transpose($c);

print "c = ";
print $c;

$d = $a x $c;
print $d;

#print $a;
#$a = $a/2;
#print $a;


$z = zeros(11);
print $z . "\n";
$x = zeros(11)->xlinvals(-1,0);
print $x . "\n";
$y = $z->xlinvals(-2,-1);
print $y ."\n";

$j = zeroes(10,2);
print $j . "\n";
$k = $j->xlogvals(1e-6,1e-3);
print $k . "\n";
$l = $j->xlinvals(1e-4,1e3);
print $l . "\n";

print "\n";
