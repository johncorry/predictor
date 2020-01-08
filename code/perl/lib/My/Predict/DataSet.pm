package My::Predict::DataSet;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(print_dataset print_all_datasets scale_dataset_as_range convert_dataset_to_rate_of_change rolling_Average_Dataset);

sub print_dataset{
   my ($dataset) = @_;
   foreach my $datum (@$dataset) {
      print "$datum\n";
   }
}

sub print_all_datasets{
   my ($allDatasets) = @_;
   foreach my $dataset(@$allDatasets) {
      print "New Dataset\n";
      print_dataset($dataset);
   }
}

sub scale_dataset_as_range{
   my ($dataset) = @_;
   # Apply the same scaling to all values.
   # Assume that the last item is the value to which the others are scaled.
   # The values will also be normalised to be between -1 to 1. 
   
   #print "\nScaling:\n";
   
   #print_dataset($dataset);
   
   my $baseline = @$dataset[-1];
   #print "Baseline = $baseline \n"

   for my $i (0..scalar(@$dataset)) {
      if (defined @$dataset[$i]){
         @$dataset[$i] = @$dataset[$i] - $baseline;
      }
   }

   my $max_datum = 0;

   for my $i (0..scalar(@$dataset)) {
      if (defined @$dataset[$i]){
         if (abs(@$dataset[$i]) > $max_datum){
            $max_datum = abs(@$dataset[$i]);
         }
      }
   }

   if ($max_datum != 0) {
      for my $i (0..scalar(@$dataset)) {
         if (defined @$dataset[$i]){
            @$dataset[$i] = (@$dataset[$i]/$max_datum);
         }
      }
   }

   # FIXME Why are we getting an extra final value printed out after scaling?
   #print_dataset($dataset);
}   

sub convert_dataset_to_rate_of_change{
   my ($dataset) = @_;
   my @datasetTemp = ();

   $datasetTemp[0] = 0; # Don't forget to nullify the first sample.

   for my $i (1..scalar(@$dataset)) {
      if (defined @$dataset[$i]){
         $datasetTemp[$i] = @$dataset[$i] - @$dataset[$i-1];
      }
   }

   for my $i (0..(scalar(@$dataset)-1)) {
      @$dataset[$i] = $datasetTemp[$i];
      #print "$i = " . @$dataset[$i] . "\n";    
   }
   
   shift @$dataset;
}
      
sub rolling_Average_Dataset {

}

1;
