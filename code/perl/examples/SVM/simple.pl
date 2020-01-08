#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::SVM;
use Algorithm::SVM::DataSet;

my $svm = new Algorithm::SVM();
my @ds;

my $labelxcount = 0;
 
while ($labelxcount < 10){
  $labelxcount = $labelxcount + 1;
  my $ds = new Algorithm::SVM::DataSet(Label => 1,
                                       Data  => [0.12 + (rand(10)/1000), 
                                                 0.25 + (rand(10)/1000), 
                                                 0.33 + (rand(10)/1000), 
                                                 0.98 + (rand(10)/1000)]);
  push(@ds, $ds);
}

my $labelycount = 0;
 
while ($labelycount < 2){
  $labelycount = $labelycount + 1;
  my $ds = new Algorithm::SVM::DataSet(Label => -1,
                                       Data  => [0.9 + (rand(10)/1000), 
                                                 0.8 + (rand(10)/1000), 
                                                 0.7 + (rand(10)/1000), 
                                                 0.1 + (rand(10)/1000)]);
  push(@ds, $ds);
}

$svm->train(@ds);
$svm->save("test.model");

my $test_ds = new Algorithm::SVM::DataSet(Label => 1,
                                          Data  => [0.9, 0.8, 0.9, 0.0]);

my $test_ds_result = $svm->predict($test_ds);
print "\nResult test ds result : $test_ds_result\n";
print $test_ds->label(), "\n";

my $accuracy = $svm->validate(2);
print "\nAccuracy : $accuracy\n";




