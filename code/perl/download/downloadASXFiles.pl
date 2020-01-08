#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Time::Piece;
use Getopt::Long;
use My::Predict::DB;
use DateTime;
use Date::Manip;
use Archive::Zip;
use WWW::Mechanize;


my $logtime = localtime; # scalar context
print "\nExecuting at $logtime\n\n";

my $extractLocation = '/home/ec2-user/data/ASX200/archive';
my $zipLocation = "$extractLocation/zip";
my $base_url = "https://www.asxhistoricaldata.com/data/week";
my $numWeeks = 5;

sub downloadASXFilesAndUnzip {

   for (my $days = 0; $days < ($numWeeks * 7); $days = $days + 7)
   { 
      my $deltastr = "$days days earlier";

      my $file_date = new Date::Manip::Date;
      my $delta = $file_date->new_delta();

      $file_date->parse("Friday");
      $delta->parse($deltastr);

      my $d = $file_date->calc($delta);
      my $date_str = $d->printf("%Y%m%d");
      print "$date_str\n";

      my $url = $base_url . $date_str . ".zip";

      print "Fetching: $url\n";

      my $mech = WWW::Mechanize->new();

      if ( not eval { $mech->get( $url ); 1} )
      { 
         print "File not found.\n";
      }
      else
      {
         my $zipname = "$zipLocation/$date_str.zip";
         $mech->save_content($zipname);

         my $zip = Archive::Zip->new($zipname);
         foreach my $member ($zip->members)
         {
            next if $member->isDirectory;
            (my $extractName = $member->fileName) =~ s{.*/}{};
            $member->extractToFileNamed("$extractLocation/$extractName");

            my $file = "$extractLocation/$extractName";

            open(my $fh, '<:encoding(UTF-8)', $file)
               or die "Could not open file '$file' $!";
   
         }
      }
   }
};

sub loadDBWithData {

   # Open DB connection.
   my $dbh = DBI->connect(
      $My::Predict::DB::Location,
      $My::Predict::DB::User,
      $My::Predict::DB::Pass,
      { RaiseError => 0, PrintError => 0 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT VERSION()");
   $sth->execute();
   $sth->finish();

   opendir(DIR, "$extractLocation");
   my @files = sort { $a <=> $b } grep(/\.txt$/,readdir(DIR));
   closedir(DIR);

   for (my $i = -$numWeeks * 5; $i < 0; $i++)
   {
      my $file = "$extractLocation/@files[$i]";
      print "\n$file\n";

      open(my $fh, '<:encoding(UTF-8)', $file)      
         or die "Could not open file '$file' $!";

      my $date = "";

      while ( my $line = <$fh>)
      {
         print $line;
         my @values = split(/,/,$line);

         if ($values[1] ne "")
         {
            my $datetime = Time::Piece->strptime($values[1],"%Y%m%d");

            $date = $datetime->strftime("%Y-%m-%d");

            print "Inserting data for ". $date . " for ". $values[0] . " " . $values[2] . "\n";

            my $sth2 = $dbh->prepare("INSERT INTO ASX200Price
                                      (Date,Code,Open,High,Low,Close,Volume) 
                                      values 
                                      ('$date',
                                      '$values[0]',
                                      '$values[2]',
                                      '$values[3]',
                                      '$values[4]',
                                      '$values[5]',
                                      '$values[6]')
                                     ON DUPLICATE KEY UPDATE
                                      Open='$values[2]',
                                      High='$values[3]',
                                      Low='$values[4]',
                                      Close='$values[5]',
                                      Volume='$values[6]' 
                                   ");

            $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
            $sth2->finish();
         }
      }
      $fh->close();
   }
   $dbh->disconnect();
};

downloadASXFilesAndUnzip();
loadDBWithData();

$logtime = localtime; # scalar context
print "\nCompleted at $logtime\n";
