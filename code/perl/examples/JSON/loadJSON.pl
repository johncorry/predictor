#!/usr/bin/perl

use JSON;
use Data::Dumper;
use strict;
use warnings;

my $filename = '/home/ec2-user/data/BTC/CoinDesk/historicalDate-2014-12-16.json';

my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

my $json = JSON->new;
my $data = $json->decode($json_text);

print $data->{'time'}->{'updated'} . "\n";

foreach my $key ( keys %{$data->{'bpi'}} ) {
   print "$key => ${$data->{'bpi'}}{$key}" . "\n";
} 

#print Dumper($data);
