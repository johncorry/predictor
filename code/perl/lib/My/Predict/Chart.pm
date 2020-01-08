package My::Predict::Chart;
use strict;
use warnings;
use Chart::Gnuplot;

#use Exporter qw(import);
use base 'Exporter';
our @EXPORT_OK = qw(chart_dataset chart_all_datasets);

sub chart_dataset{
   my ($dataset) = @_;

   my $chart = Chart::Gnuplot->new(
      output => "dataset.jpeg",
   );

   my @gnuDataSets;

   my $x_count = 0;
   my @xy = ();
   foreach my $datum (@$dataset) {
      push @xy, [$x_count, $datum];
      $x_count++;
   }
   my $gnuDataSet = Chart::Gnuplot::DataSet->new(
      points => \@xy,
      style => "linespoints"
   );

   push @gnuDataSets, $gnuDataSet;
   $chart->plot2d(@gnuDataSets);
}



sub chart_all_datasets{
   my ($allDatasets) = @_;

   my $chart = Chart::Gnuplot->new(
      output => "datasets.jpeg",
   );

   my @gnuDataSets;

   foreach my $dataset(@$allDatasets) {
      my $x_count = 0;
      my @xy = ();
      foreach my $datum (@$dataset) {
         push @xy, [$x_count, $datum];
         $x_count++;
      }
      my $gnuDataSet = Chart::Gnuplot::DataSet->new(
          points => \@xy,
          style => "linespoints"
      );
      push @gnuDataSets, $gnuDataSet;
   }
   $chart->plot2d(@gnuDataSets);
}

1;
