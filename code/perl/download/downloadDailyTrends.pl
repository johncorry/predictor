#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use My::Predict::DB;

my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

# Open DB connection.
my $dbh = DBI->connect(
    $My::Predict::DB::Location,
    $My::Predict::DB::User,
    $My::Predict::DB::Pass,
    { RaiseError => 0, PrintError => 0 },
) or die $DBI::errstr;

####################

my $sth = $dbh->prepare("SELECT Code, Name FROM PriceData.ASX200Company WHERE Sector <> ?");
      $sth->execute("Not Applic");

while (my @row = $sth->fetchrow_array()) {

   my $code = $row[0];
   my $name = $row[1];
   
   if ($code eq ""){
        next;
   }

   #if ($code lt "MXT"){
   #     next;
   #}
   
   my $company_name = $name;
   $company_name =~ s/\.NET//g;
   $company_name =~ s/\.COM\.AU//g;
   $company_name =~ s/\.COM//g;
   $company_name =~ s/CO\.HOLD\.LTD//g;
   $company_name =~ s/LIMITED//g;
   $company_name =~ s/CORPORATION//g;
   $company_name =~ s/\.//g;
   $company_name =~ s/\,//g;
   $company_name =~ s/\bLTD\b//g;
   $company_name =~ s/\bPLC\b//g;
   $company_name =~ s/\bPTY\b//g;
   $company_name =~ s/\bPL\b//g;
   $company_name =~ s/HOLDINGS//g;
   $company_name =~ s/\bNL\b//g;
   $company_name =~ s/HOLDING GROUP//g;
   $company_name =~ s/\(.*\)//g;
   $company_name =~ s/\bINC\b//g;
   $company_name =~ s/\bAG\b//g;

   $company_name =~ s/^\s+|\s+$//g;
   $company_name = join '', map { ucfirst lc $_ } split /(\s+)/, $company_name;

   $logtime = localtime; # scalar context
   print "\n\n$logtime\n";
   print $code . " " . $name . "\n";
   print $company_name . "\n";

   open(my $cmd, '-|', '/home/jcorry/git-checkout/code/perl/download/trend_daily.py', $company_name) or die $!;
   while (my $line = <$cmd>) {

     my @tokens = split(/ /, $line);
     print $code . " " . $tokens[0] . " " . $tokens[2] . " " . $tokens[3];
     my $date = $tokens[0] . " " . $tokens[1];
     my $trend = $tokens[2];
     my $isPartial = $tokens[3];
     $isPartial =~ s/^\s+|\s+$//g; 

     if ($isPartial eq "False"){  
        print "Inserting data for " . $date . " " . $code . " " . $trend . "\n";

        my $sth2 = $dbh->prepare("INSERT INTO PriceData.ASXTrend
                                  (Date,Code,Trend,Series)
                                  values
                                  ('$date',
                                   '$code',
                                   '$trend',
                                   'Daily')
                                  ON DUPLICATE KEY UPDATE
                                   Trend='$trend'
                                 ");
        #$sth2->execute();
        $sth2->execute or die "Can't execute SQL statement: $DBI::errstr\n";
        $sth2->finish();
     }
   }
   close $cmd;

   # Google limits how many calls you can make so need to slow it down.
   sleep(30);
   #exit;
}
