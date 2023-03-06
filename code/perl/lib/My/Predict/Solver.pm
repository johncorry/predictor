#!/usr/bin/perl

package Solver;

use strict;
use warnings;

use Algorithm::SVM;
use Algorithm::SVM::DataSet;
use DBI;
use Time::Piece;

use My::Predict::DB;
use My::Predict::Problem;

sub new
{
   my $class = shift;
   my $self = {
      _problem           => shift,
      _firstTraining     => 1
   };
   
   # Model Cache
   $self->{_model} = "/home/ec2-user/models/" . $self->{_problem}->getCode . ".model";

   bless $self, $class;
   return $self;
}

sub train {

   my ( $self ) = @_;

   my @ds;
   foreach my $feature_array($self->{_problem}->getTrainingSet) {
      my $label = shift @$feature_array;
      #print "label         = " . $label . "\n";
      #print "feature_array =  @$feature_array \n";
      my $ds = new Algorithm::SVM::DataSet(Label => $label,
                                           Data  => $feature_array);
      push(@ds,$ds);
   }

   print "Result Code                    : " . $self->{_problem}->getCode() . "\n";
   print "Result Number of features      : " . $self->{_problem}->getNumFeatures() . "\n";
   print "Result Number of data sets     : " . $self->{_problem}->getNumDataSets() . "\n";
   print "Result Number of tests         : " . $self->{_problem}->getNumTests() . "\n";
   print "Result Noise cut off           : " . $self->{_problem}->getNoiseCutoff() . "\n";
   print "Result Number of training sets : " . @ds . "\n";

   my @CValues = (1,100,10000,100000); #(1,10,100,1000,10000,100000); # SVM tuning param.
   my @epsilonValues = (0.1,0.5,0.9); #(0.01,0.1,0.5,0.9,0.99); # SVM tuning param.
   my @gammaValues = (0.5,0.1,0.01);
   my @kernalTypes = ('polynomial'); #'linear', 'polynomial', 'radial','sigmoid' 

   my $accuracy = 0;
   my $maxAccuracy = 0;
   my @maxAccuracyParams = ();

   print "Result Tuning SVM\n";
   my $trained = 0;

   foreach my $CValue (@CValues) {
      foreach my $gammaValue (@gammaValues) {
         foreach my $kernalType (@kernalTypes) {
         foreach my $epsilonValue (@epsilonValues) {
            $self->{_SVM} = new Algorithm::SVM();
            #print "Result Params :  $kernalType $CValue $epsilonValue\n";
            $self->{_SVM}->kernel_type($kernalType);  
            $self->{_SVM}->C($CValue);
            $self->{_SVM}->gamma($gammaValue);
            $self->{_SVM}->epsilon($epsilonValue);
            #$self->{_SVM}->coef0(0);
            #$self->{_SVM}->degree(3);
            #$self->{_SVM}->svm_type('C-SVC');
            #$self->{_SVM}->train(@ds);

            #if ($trained == 0) {
               $self->{_SVM}->train(@ds);
            #   $trained = 1;

               ##FIXME This is a hack.  You would expect that if the same data set and parameters are 
               ##      used you would get the same model produced between a train and retrain. This 
               ##      isn't so. Why the nondeterminism? The results between retrains seems to be a 
               ##      bit better but I'm not 100% sure. Given that we are about to repeatedly retrain
               ##      in order to tune the paras, I have thrown away the first model generated.  
               #$self->{_SVM}->train(@ds);
               ##$self->{_SVM}->retrain();
            #}
            #else {
            #   if ($self->{_SVM}->retrain() == 0){
            #      print "Result Retain failed.\n";
            #   }
            #}
            
            $accuracy = $self->{_SVM}->validate(3);
            printf("Result Best -> Accuracy : %.1f kernal %s C %d gamma %.2f epsilon %.2f\n", $accuracy, $kernalType, $CValue, $gammaValue, $epsilonValue);

            if ($accuracy > $maxAccuracy){
               $maxAccuracy = $accuracy;
               @maxAccuracyParams = ("kernal", $kernalType, "C", $CValue, "gamma", $gammaValue, "epsilon", $epsilonValue);
               $self->{_SVM}->save($self->{_model});
            }
         }
         }
      }
   }


   $self->{_problem}->setAccuracy($maxAccuracy);
   printf ("Result Best Accuracy : %.1f with ", $maxAccuracy);
   foreach  my $param (@maxAccuracyParams){
      print "$param ";
   }

   print "\n";

}

sub getAccuracy {

   my ( $self ) = @_;

   return $self->{_accuracy};

} 

sub predict {

   my ( $self ) = @_;

   my @testSetSolution = $self->runPrediction($self->{_problem}->getTestingSet());
   $self->{_problem}->setTestSolution(@testSetSolution);

   my @predictionSetSolution = $self->runPrediction($self->{_problem}->getPredictionSet);
   $self->{_problem}->setPredictionSolution(@predictionSetSolution);

}

sub runPrediction {

   my ($self, @prediction_set) = @_;

   my @prediction_solution;
   my $model = $self->{_model};

   #$self->{_SVM} = new Algorithm::SVM();

   if (-e $model){

      $self->{_SVM}->load($model);
   
      foreach my $feature_array (@prediction_set) {
         my $label = shift @$feature_array;
         #print "label         = " . $label . "\n";
         #print "feature_array =  @$feature_array \n";
         my $ds = new Algorithm::SVM::DataSet(Label => 0,
                                              Data  => $feature_array);
         my $test_ds_result = $self->{_SVM}->predict($ds);

         push @prediction_solution, $test_ds_result;
      }
   }
   else {
      print "Result Could not find model file:\n";
      print $model . "\n";
   }

   return @prediction_solution;
}

sub saveResult {

   my ($self) = @_;

   my $date =  $self->{_problem}->getFinalDate() . " 00:00:00";
   my ($prediction, $bestGain, $sitAndHoldGain, $gain, $accuracy, @result) = $self->{_problem}->getSolution(0);

   print "Result Saving...\n";

   # Open DB connection.
   my $dbh = DBI->connect(
       $My::Predict::DB::Location,
       $My::Predict::DB::User,
       $My::Predict::DB::Pass,
       { RaiseError => 0, PrintError => 0 },
   ) or die $DBI::errstr;

   my $sth = $dbh->prepare("SELECT VERSION()");
   $sth->execute();

   print "Result               date " . $date . "\n"; 
   print "Result         prediction " . $prediction . "\n"; 
   print "Result               gain " . $gain . "\n";
   print "Result           bestGain " . $bestGain . "\n";
   print "Result     sitAndHoldGain " . $sitAndHoldGain . "\n";
   print "Result                 ut " . $self->{_problem}->getUpperThreshold() . "\n";
   print "Result                 lt " . $self->{_problem}->getLowerThreshold() . "\n";
   print "Result                 nt " . $self->{_problem}->getNumTests() . "\n";
   print "Result                 ts " . $self->{_problem}->getTimeSeries() . "\n";
   print "Result       includeIndex " . $self->{_problem}->getIncludeIndex() . "\n";
   print "Result        includeETFs " . $self->{_problem}->getIncludeETFs() . "\n";
   print "Result          includeFX " . $self->{_problem}->getIncludeFX() . "\n";
   print "Result  includeDaysMonths " . $self->{_problem}->getIncludeDaysMonths() . "\n";
   print "Result  includeTimeSeries " . $self->{_problem}->getIncludeTimeSeries() . "\n";
   print "Result includeFrequencies " . $self->{_problem}->getIncludeFrequencies() . "\n";
   print "Result includeTrends " . $self->{_problem}->getIncludeTrends() . "\n";

   $dbh->do('REPLACE INTO Prediction
            (Date, Code, Period, UpperThreshold, LowerThreshold, TimeSeries, IncludeIndex, IncludeETFs, IncludeFX, IncludeDaysMonths, IncludeFrequencies, IncludeTimeSeries, Prediction, BestGain, SitAndHoldGain, Gain, Accuracy) 
            VALUES  
            (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
            undef,
            $date,
            $self->{_problem}->getCode(),
            $self->{_problem}->getForecastPeriod(),
            $self->{_problem}->getUpperThreshold(),
            $self->{_problem}->getLowerThreshold(),
            $self->{_problem}->getTimeSeries(),
            $self->{_problem}->getIncludeIndex(),
            $self->{_problem}->getIncludeETFs(),
            $self->{_problem}->getIncludeFX(),
            $self->{_problem}->getIncludeDaysMonths(),
            $self->{_problem}->getIncludeFrequencies(),
            $self->{_problem}->getIncludeTimeSeries(),
            $prediction,
            $bestGain,
            $sitAndHoldGain,
            $gain,
            $accuracy);


   #$sth->execute();
   $sth->finish();
   $dbh->disconnect();
}

1;
