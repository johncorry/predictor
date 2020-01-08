#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use MIME::Lite;
#use Time::Piece;
use DateTime;
use Date::Manip;

use My::Predict::DB;
#use My::Predict::Problem;
#use My::Predict::Solver;
use My::Predict::ASX200Data;


print "\nResult Today is " . gmtime() . "\n";
my $startLogTime = localtime; # scalar context
print "\nResult Executing at $startLogTime\n\n";

my $ASX200Data = new ASX200Data();

my $portfolioSetHTML;
my $predictionSetHTML;


my $date = new Date::Manip::Date;
$date->parse("28 business days ago");

print "Date " . $date->printf("%Y-%m-%d") . "\n";
my $date_str = $date->printf("%Y-%m-%d 00:00:00");

$date->parse("1 business day ago");
my $finalDate = $date->printf("%Y-%m-%d");


# Open DB connection.
my $dbh = DBI->connect(
      $My::Predict::DB::Location,
      $My::Predict::DB::User,
      $My::Predict::DB::Pass,
      { RaiseError => 0, PrintError => 1 },
   ) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT Code FROM PriceData.Portfolio WHERE SaleDate IS NULL");
$sth->execute();

my @portfolio;

while (my @row = $sth->fetchrow_array()){
  my $code = $row[0];
  #print $code . "\n";
  push @portfolio, $code;
}

for my $portfolioCode (@portfolio){

   my $sth2 = $dbh->prepare("SELECT DISTINCT Date, Prediction, Accuracy, Gain, BestGain, SitAndHoldGain 
                             FROM PriceData.Prediction 
                             WHERE Code = '$portfolioCode' 
                             AND Date > '$date_str'");
   $sth2->execute()
     or die "Can't execute SQL statement: $DBI::errstr\n";
   #print $portfolioCode . "\n";
   $portfolioSetHTML = $portfolioSetHTML . "<div><h2><a href=\"http://finance.yahoo.com/q/pr?s=$portfolioCode.AX+Profile\">$portfolioCode</a></h2>\n";

   $portfolioSetHTML = $portfolioSetHTML . qq{ 
      <p>
          <img border="0" alt="$portfolioCode" src="https://www.reuters.wallst.com/reuters/enhancements/chartapi/chart_api.asp?width=640&height=350&duration=20&showLastClose=1&headerType=quote&lowers=volume&symbol=$portfolioCode.AX" width="640" height="350">
      </p>
      <p>
          <img border="0" alt="$portfolioCode" src="https://www.reuters.wallst.com/reuters/enhancements/chartapi/chart_api.asp?width=640&height=350&duration=365&lowers=volume&symbol=$portfolioCode.AX" width="640" height="350">
      </p>
};

   $portfolioSetHTML = $portfolioSetHTML
                        . "<p>"
                        . "<table style=\"width:100%\" align=\"left\">";
  
   $portfolioSetHTML = $portfolioSetHTML
                        . "<tr>"
                        . "<th>Date</th>"
                        . "<th>Prediction</th>"
                        . "<th>Accuracy</th>"
                        . "<th>Gain</th>"
                        . "<th>Best Gain</th>"
                        . "<th>Sit & Hold</th>"
                        . "</tr>";

 
   while (my @row = $sth2->fetchrow_array()){
      #print "\t" . $row[0] . " " . $row[1] . " " . $row[2] . " " . $row[3] . " " . $row[4] . " " . $row[5] . "\n";   

 
     my @tokens = split(/ /, $row[0]);
     $portfolioSetHTML = $portfolioSetHTML
                          . "<tr>"
                          . "<td>$tokens[0]</td>"
                          . "<td>$row[1]</td>"
                          . "<td>$row[2]</td>"
                          . "<td>$row[3]</td>"
                          . "<td>$row[4]</td>"
                          . "<td>$row[5]</td>"
                          . "</tr>";
   }
   $portfolioSetHTML = $portfolioSetHTML
                        . "</table>"
                        . "</p>";


   $sth2 = $dbh->prepare("SELECT * FROM PriceData.Portfolio WHERE Code = ? and SaleDate IS NULL");
   $sth2->execute($portfolioCode);

   my @portfolioRow = $sth2->fetchrow_array();

   my @words = split / /, $portfolioRow[1];
   my $purchaseDate = $words[0];
   my $purchasePrice = $portfolioRow[3];
   my $purchaseQuantity = $portfolioRow[5];
   my $date = $finalDate;
   #my $close = 1; #Hack
   my $close = $ASX200Data->getClose($portfolioCode,$finalDate);

   #my $close = $problem->getClose($date);
   my $percentageGain = (($close - $purchasePrice)/$purchasePrice) * 100;
   $percentageGain = sprintf "%.2f", $percentageGain;

   my $profit = ($close - $purchasePrice) * $purchaseQuantity;
   $profit = sprintf "%.2f", $profit;

   $portfolioSetHTML = $portfolioSetHTML
                        . "<table style=\"width:100%\" align=\"left\">";

   $portfolioSetHTML = $portfolioSetHTML
                        . "<tr>"
                        . "<td>Purchased</td>"
                        . "<td>$purchaseDate</td>"
                        . "</tr>";

   $portfolioSetHTML = $portfolioSetHTML
                        . "<tr>"
                        . "<td>Price</td>"
                        . "<td>$purchasePrice</td>"
                        . "</tr>";

   $portfolioSetHTML = $portfolioSetHTML
                        . "<tr>"
                        . "<td>Close</td>"
                        . "<td>$close</td>"
                        . "</tr>";

   $portfolioSetHTML = $portfolioSetHTML
                        . "<tr>"
                        . "<td>Profit</td>"
                        . "<td>$profit  ($percentageGain\%)</td>"
                        . "</tr>";

   $portfolioSetHTML = $portfolioSetHTML
                        . "</table>";

}  

$date->parse("1 business day ago");
#print "Date " . $date->printf("%Y-%m-%d") . "\n";
$date_str = $date->printf("%Y-%m-%d 00:00:00");

$sth = $dbh->prepare("SELECT DISTINCT Code 
                      FROM PriceData.Prediction 
                      WHERE Date = '$date_str'
                      AND Prediction = 1
                      ORDER BY Code");
$sth->execute();

$date->parse("28 business days ago");
#print "Date " . $date->printf("%Y-%m-%d") . "\n";
$date_str = $date->printf("%Y-%m-%d 00:00:00");


while (my @row = $sth->fetchrow_array()){
  my $code = $row[0];
  #print $code . "\n";
  my $sth2 = $dbh->prepare("SELECT DISTINCT Date, Prediction, Accuracy, Gain, BestGain, SitAndHoldGain 
                            FROM PriceData.Prediction 
                            WHERE Code = '$code'   
                            AND Date > '$date_str'");
  $sth2->execute()
     or die "Can't execute SQL statement: $DBI::errstr\n";
  #print $code . "\n";
 
  $predictionSetHTML = $predictionSetHTML . "<div><h2><a href=\"http://finance.yahoo.com/q/pr?s=$code.AX+Profile\">$code</a></h2>\n";
  $predictionSetHTML = $predictionSetHTML . qq{ 
      <p>
          <img border="0" alt="$code" src="https://www.reuters.wallst.com/reuters/enhancements/chartapi/chart_api.asp?width=640&height=350&duration=20&showLastClose=1&headerType=quote&lowers=volume&symbol=$code.AX" width="640" height="350">
      </p>

      <p>
          <img border="0" alt="$code" src="https://www.reuters.wallst.com/reuters/enhancements/chartapi/chart_api.asp?width=640&height=350&duration=365&lowers=volume&symbol=$code.AX" width="640" height="350">
      </p>
};
  $predictionSetHTML = $predictionSetHTML
                        . "<p>"
                        . "<table style=\"width:100%\" align=\"left\">";
 
  $predictionSetHTML = $predictionSetHTML
                        . "<tr>"
                        . "<th>Date</th>"
                        . "<th>Prediction</th>"
                        . "<th>Accuracy</th>"
                        . "<th>Gain</th>"
                        . "<th>Best Gain</th>"
                        . "<th>Sit & Hold</th>"
                        . "</tr>";


  while (my @row = $sth2->fetchrow_array()){
      #print "\t" . $row[0] . " " . $row[1] . " " . $row[2] . " " . $row[3] . " " . $row[4] . " " . $row[5] . "\n";   

     my @tokens = split(/ /, $row[0]);

     $predictionSetHTML = $predictionSetHTML
                          . "<tr>"
                          . "<td>$tokens[0]</td>"
                          . "<td>$row[1]</td>"
                          . "<td>$row[2]</td>"
                          . "<td>$row[3]</td>"
                          . "<td>$row[4]</td>"
                          . "<td>$row[5]</td>"
                          . "</tr>";
   }
   $predictionSetHTML = $predictionSetHTML
                        . "</table>"
                        . "</p>";
}   
 
$date->parse("1 business day ago");
#print "Date " . $date->printf("%Y-%m-%d") . "\n";
$date_str = $date->printf("%Y-%m-%d 00:00:00");
my $date_title = $date->printf("%Y-%m-%d");

my $endReportTime = localtime; # scalar context
my $reportGenTime = $endReportTime - $startLogTime;

my $data = qq{
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Predictions for - $date_title</title>
      <style>
        table {
          font-family: arial, sans-serif;
          border-collapse: collapse;
          width: 100%;
        }

      td, th {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
      }

      tr:nth-child(even) {
        background-color: #dddddd;
      }
      </style>
    </head>
    <body>
      <h1>Predictions for - $date_title</h1>
      <h2>Portfolio Predictions</h2>
      $portfolioSetHTML
      <h2>Newest Predictions</h2>
      $predictionSetHTML
      <p>Report generation time: $reportGenTime</p>
    </body>
  </html> 
};


my $subject   = "Predictions for $date_title";
#my $sender    = 'ubuntu@ip-172-31-26-25.ap-southeast-2.compute.internal';
my $sender    = 'predictor@thefuture.com';
my $recipient = 'mrjohncorry@gmail.com';

my $mime = MIME::Lite->new(
#    'From'    => $sender,
    'To'      => $recipient,
    'Subject' => $subject,
    'Type'    => 'text/html',
    'Data'    => $data,
);

$mime->send() or die "Failed to send mail\n";

 
