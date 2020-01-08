#!/usr/bin/perl

use PDL;

$a = pdl [[0,2,4,6],
          [2,4,6,8],
          [4,6,8,10],
          [6,8,10,12]];

$b = transpose pdl [[-1,0,0,1],
                    [0,-1,0,1],
                    [0,0,-1,1], 
                   ];

print "a = ";
print $a;

print "b = ";
print $b;

$c = $a x $b;

print "c = ";
print $c;

print $c/3;

