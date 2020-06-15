#!/usr/bin/perl

package Problem;

use PDL;
use PDL::NiceSlice;
use PDL::Finance::TA; # https://gist.github.com/preaction/3df4d95b357ce9810023
use PDL::FFT;

use My::Predict::ASX200Data;
use My::Predict::ASXIndicesData;
use My::Predict::DataLookUp;
use My::Predict::PricePDLSet;

sub new
{
   my $class = shift;
   my $self = {
      _code               => shift,
      _forecastPeriod     => shift,
      _timeMachine        => shift,
      _forcePrediction    => shift // 0,
      _numTests           => 40,
      _upperThreshold     => 0.01,
      _lowerThreshold     => -0.01,
      _minSamples         => 500,
      _minClosingPrice    => 0.05,
      _noiseCutoff        => 120,
      _timeSeries         => 10,
      _freqSeries         => 200,
      _includeIndex       => 0,
      _includeETFs        => 0,
      _includeFX          => 0,
      _includeDaysMonths  => 0,
      _includeFrequencies => 0,
      _includeTimeSeries  => 0,
      _accuracy           => 0,
   };

   $self->{_ASX200Data} = new ASX200Data();
   $self->{_priceMap} = $self->{_ASX200Data}->getPriceSeries($self->{_code});
   $self->{_dateSeries} = $self->{_ASX200Data}->getDateSeries($self->{_code});

   my $time_machine_counter = 0;
   while ($time_machine_counter < $self->{_timeMachine}){
      my $popped = pop @{$self->{_dateSeries}};
      print "Result $time_machine_counter popped : $popped\n";
      $time_machine_counter++;
   }

   # Only consider the last 2000 days.
   while (2000 < scalar (@{$self->{_dateSeries}})){
      my $shifted = shift @{$self->{_dateSeries}};
      print "Result removing : $shifted\n";
   }
   ####


   $self->{_numSamples} = scalar (@{$self->{_dateSeries}});
   $self->{_finalDate} = $self->{_dateSeries}->[$self->{_numSamples} -1];

   $self->{_ASXIndicesData} = new ASXIndicesData();
   $self->{_FXAUDMap} = My::Predict::DataLookUp::create_FXAUD_Look_Up();
   print "Result creating daily ETF look up\n";
   # Bug: If there are problems with the map, missing data in this case then
   #      things down strem of this can't handle it.
   $self->{_ETFMap} = My::Predict::DataLookUp::create_Daily_ETF_Look_Up();
   print "Result done creating daily ETF look up\n";

   $self->{_predictionMap} = {};

   bless $self, $class;
   return $self;
}

sub setAccuracy {

   my ( $self, $accuracy ) = @_;

   $self->{_accuracy} = $accuracy;
}

sub getSolution {
   my ( $self, $print ) = @_;

   my $own = 0;
   my $stake = 1.0;
   my $bestGain = 1.0;
   my $testStartDate = $self->{_dateSeries}[($self->{_numSamples} - $self->{_numTests})];
   my $sitAndHoldGain = 1 + $self->getGainOverPeriod($testStartDate,$self->{_finalDate});
   my $finalPrediction = 0;
   my @result;


   push @result, sprintf("Result Date           \tPrice\tDGain\tOwn\tPred\tAct\tPGain\tBGain\tStake\n");

   foreach my $i (($self->{_numSamples} - $self->{_numTests}) .. ($self->{_numSamples} -1)){
      my $start_date = $self->{_dateSeries}[$i];
      my $next_date = $self->{_dateSeries}[$i+1];
      my $forecast_date = $self->{_dateSeries}[$i+$self->{_forecastPeriod}];


      my $prediction = $self->getPrediction($start_date);
      $finalPrediction = $prediction;

      if ($prediction == 1){
         $own = 1;
      }
      elsif ($prediction == -1){
         $own = 0;
      }

      if ($own){
         $stake = $stake + ($stake * $self->getGainOverPeriod($start_date, $next_date));
      }

      if ( $forecast_date ne "") {

         #if ($own){
         #   $stake = $stake + ($stake * $self->getGainOverPeriod($start_date, $forecast_date));
         #}


         my $reality = $self->getReality($start_date, $forecast_date);

         if ($reality == 1){
            $bestGain = $bestGain + ($bestGain * $self->getGainOverPeriod($start_date, $next_date));
         }

         push @result, sprintf ("Result %s\t% .3f\t% .3f\t% d\t% d\t% d\t% .3f\t% .3f\t% .3f\n",
                                 $start_date,
                                 $self->getClosingPrice($start_date),
                                 $self->getGainOverPeriod($start_date, $next_date),
                                 $own,
                                 $prediction,
                                 $reality,
                                 $self->getGainOverPeriod($start_date, $forecast_date),
                                 $bestGain,
                                 $stake);

      }
      else {
         push @result, sprintf ("Result %s\t% .3f\t% .3f\t% d\t% d\t -\t -\t -\t -\n",
                                 $start_date,
                                 $self->getClosingPrice($start_date),
                                 $self->getGainOverPeriod($start_date, $next_date),
                                 $own,
                                 $prediction,
                                 $self->getGainOverPeriod($start_date, $next_date));
      }
   }

   print "Result result:\n";

   for my $r (@result){
      print $r;
   }


   return ($finalPrediction, $bestGain, $sitAndHoldGain, $stake, $self->{_accuracy}, @result);
}

sub printParameters {
   my ( $self ) = @_;

   print "Result     upperThreshold " . $self->getUpperThreshold() . "\n";
   print "Result     lowerThreshold " . $self->getLowerThreshold() . "\n";
   print "Result           numTests " . $self->getNumTests() . "\n";
   print "Result         timeSeries " . $self->getTimeSeries() . "\n";
   print "Result       includeIndex " . $self->getIncludeIndex() . "\n";
   print "Result        includeETFs " . $self->getIncludeETFs() . "\n";
   print "Result          includeFX " . $self->getIncludeFX() . "\n";
   print "Result  includeDaysMonths " . $self->getIncludeDaysMonths() . "\n";
   print "Result  includeTimeSeries " . $self->getIncludeTimeSeries() . "\n";
   print "Result includeFrequencies " . $self->getIncludeFrequencies() . "\n";
}

sub getCode {
   my ( $self ) = @_;
   return $self->{_code};
}

sub getFinalDate {
   my ( $self ) = @_;
   return $self->{_finalDate};
}

sub getForecastPeriod {
   my ( $self ) = @_;
   return $self->{_forecastPeriod};
}

sub getNumSamples {
   my ( $self ) = @_;
   return $self->{_numSamples};
}

sub getNumTests {
   my ( $self ) = @_;
   return $self->{_numTests};
}

sub getUpperThreshold {
   my ( $self ) = @_;
   return $self->{_upperThreshold};
}

sub getLowerThreshold {
   my ( $self ) = @_;
   return $self->{_lowerThreshold};
}

sub getNoiseCutoff {
   my ( $self ) = @_;
   return $self->{_noiseCutoff};
}

sub getClosingPrice {
   my ( $self, $date ) = @_;

   my $close = 0;
   if ($self->{_priceMap}->{$date} ne ""){
      $close = $self->{_priceMap}->{$date}->getClose();
   }
   return $close;
}

sub setTestSolution {
   my ( $self, @testSetSolution ) = @_;

   foreach my $i (($self->getNumDataSets() - $self->getNumTests())..($self->getNumDataSets() - $self->getForecastPeriod())) {
      my $date = $self->{_dateSeries}[$i];
      my $prediction = shift @testSetSolution;
      $self->setPrediction($date,$prediction);
   }
}

sub setPredictionSolution {
   my ( $self, @predictionSetSolution ) = @_;

   foreach my $i (($self->getNumDataSets() - $self->getForecastPeriod())..($self->getNumDataSets() - 1)) {
      my $date = $self->{_dateSeries}[$i];
      my $prediction = shift @predictionSetSolution;
      $self->setPrediction($date,$prediction);
   }
}

sub setPrediction {
   my ( $self, $date, $prediction) = @_;
   $self->{_predictionMap}->{$date} = $prediction;
}

sub getPrediction {
   my ( $self, $date ) = @_;
   return $self->{_predictionMap}->{$date};
}

sub getReality {
   my ( $self, $start_date, $end_date) = @_;

   my $reality = 0;

   if ($self->getGainOverPeriod($start_date, $end_date) >= $self->getUpperThreshold()){
      $reality = 1;
   }
   elsif ($self->getGainOverPeriod($start_date, $end_date) <= $self->getLowerThreshold()){
      $reality = -1;
   }

   return $reality;
}

sub getGainOverPeriod {
   my ( $self, $start_date, $end_date ) = @_;

   my $gain = 0;

   if ($start_date ne "" and $end_date ne "") {
      $gain = ($self->getClosingPrice($end_date) - $self->getClosingPrice($start_date))/$self->getClosingPrice($start_date);
   }

   return $gain;
}

sub setUpperThreshold {
   my ( $self, $upperThreshold) = @_;
   $self->{_upperThreshold} = $upperThreshold;
}

sub setLowerThreshold {
   my ( $self, $lowerThreshold) = @_;
   $self->{_lowerThreshold} = $lowerThreshold;
}

sub setNumTests {
   my ( $self, $numTests) = @_;
   $self->{_numTests} = $numTests;
}

sub setTimeSeries {
   my ( $self, $timeSeries) = @_;
   $self->{_timeSeries} = $timeSeries;
}

sub getTimeSeries {
   my ( $self ) = @_;
   return $self->{_timeSeries};
}

sub includeIndex {
   my ( $self, $includeIndex ) = @_;
   return $self->{_includeIndex} = $includeIndex;
}

sub getIncludeIndex {
   my ( $self ) = @_;
   return $self->{_includeIndex};
}

sub includeETFs {
   my ( $self, $includeETFs ) = @_;
   return $self->{_includeETFs} = $includeETFs;
}

sub getIncludeETFs {
   my ( $self ) = @_;
   return $self->{_includeETFs};
}

sub includeFX {
   my ( $self, $includeFX ) = @_;
   return $self->{_includeFX} = $includeFX;
}

sub getIncludeFX {
   my ( $self ) = @_;
   return $self->{_includeFX};
}

sub includeDaysMonths {
   my ( $self, $includeDaysMonths ) = @_;
   return $self->{_includeDaysMonths} = $includeDaysMonths;
}

sub getIncludeDaysMonths {
   my ( $self ) = @_;
   return $self->{_includeDaysMonths};
}

sub includeFrequencies {
   my ( $self, $includeFrequencies ) = @_;
   return $self->{_includeFrequencies} = $includeFrequencies;
}

sub getIncludeFrequencies {
   my ( $self ) = @_;
   return $self->{_includeFrequencies};
}

sub includeTimeSeries {
   my ( $self, $includeTimeSeries ) = @_;
   return $self->{_includeTimeSeries} = $includeTimeSeries;
}

sub getIncludeTimeSeries {
   my ( $self ) = @_;
   return $self->{_includeTimeSeries};
}

sub canPredict {
   my ( $self ) = @_;

   # If the user sets a flag then force the prediction.

   if ($self->{_forcePrediction}){
     return 1;
   }

   # Check that a number of basic prerequisites are met otherwise the prediction will be rubbish.

   if ($self->{_numSamples} < $self->{_minSamples}){
      print "Result $self->{_numSamples} is less than $self->{_minSamples} which is the minimum number of samples.\n";
      print "Result Cannot predict.\n";
      return 0;
   }

   my $closing_price = $self->{_priceMap}->{$self->{_finalDate}}->getClose();

   if ($closing_price < $self->{_minClosingPrice}){
      print "Result $closing_price is less than $self->{_minClosingPrice} which is the minimum closing price.\n";
      print "Result Cannot predict.\n";
      return 0;
   }

   my $accumulatedAbsChange = 0;
   my $accumulatedVolume = 0;

   for (my $i = 1; $i < $self->{_numTests} -1 ; $i++){

      my $volume = $self->{_priceMap}->{${$self->{_dateSeries}}[-$i]}->getVolume();
      my $closingPrice = $self->{_priceMap}->{${$self->{_dateSeries}}[-$i]}->getClose();
      my $prevClosingPrice = $self->{_priceMap}->{${$self->{_dateSeries}}[-($i+1)]}->getClose();
      $accumulatedAbsChange = $accumulatedAbsChange + abs($closingPrice - $prevClosingPrice);
      $accumulatedVolume = $accumulatedVolume + ($volume * $closingPrice);
   }

   if ($accumulatedAbsChange == 0) {
      # A better test here would be some sort of standard diviation.
      print "Result Accumulated absolute change is $acculatedAbsChange.\n";
      print "Result Cannot predict.\n";
      return 0;
   }

   my $averageVolume = $accumulatedVolume/$self->{_numTests};
   my $minmumDailyVol = 100000;

   if ($averageVolume  < $minmumDailyVol) {
      print "Result Average daily volume is $averageVolume is less than $minmumDailyVol.\n";
      print "Result Cannot predict.\n";
      return 0;
   }

   print "Result Can predict.\n";
   return 1;
}

sub getSector {
   my ( $self ) = @_;
   return $self->{_ASXIndicesData}->getIndexCode($self->{_code});
}

sub createProblem {
   my ( $self ) = @_;

   my $problemPDL = pdl [];

   if ($self->canPredict){

      $problemPDL = $self->createTargetGainPDL;
      my $featurePDL = $self->createFeaturePDL;
      $problemPDL = $problemPDL->glue(1,$featurePDL);

      if($self->{_includeIndex}){
         my $indexCode = $self->{_ASXIndicesData}->getIndexCode($self->{_code});
         print "Result " . $self->{_code} . " is in $indexCode sector.\n";

         if ($indexCode ne "NONE"){
            my $indexMap_ref = $self->{_ASXIndicesData}->getIndexSeries($indexCode);
            my $indexPricePDLSet = new PricePDLSet($indexMap_ref, $self->{_dateSeries});
            my $indexFeaturePDL = $self->createFeaturePDL(\$indexPricePDLSet);
            $problemFeaturePDL = $problemPDL->glue(1,$indexFeaturePDL);
         }
      }

      if($self->{_includeFX}){
         print "Result Including FX.\n";
         my $fxPDL = $self->createFXPDL;
         #print $fxPDL . "\n";
         #exit;
         $problemPDL = $problemPDL->glue(1,$fxPDL);
      }

      if($self->{_includeETFs}){
         print "Result Including ETFs.\n";
         my $ETFsPDL = $self->createETFsPDL;
         $problemPDL = $problemPDL->glue(1,$ETFsPDL);
      }

      if($self->{_includeDaysMonths}){
         print "Result Including Days and Months.\n";
         my $daysMonthsPDL = $self->createDaysMonthsPDL;
         $problemPDL = $problemPDL->glue(1,$daysMonthsPDL);
      }
  }

   $problemPDL = transpose $problemPDL;

   $self->{_problemPDL} = $problemPDL;

   my $summary = sum $self->{_problemPDL};
   printf ("Result Problem summary         :   %.2f\n",$summary);
}

sub getNumFeatures {
   my ( $self ) = @_;

   return $self->{_problemPDL}->getdim(0);
}

sub getNumDataSets {
   my ( $self ) = @_;

   return $self->{_problemPDL}->getdim(1);
}

sub getTrainingSet {
   my ( $self ) = @_;

   my @training_set;
   my $problem_pdl = $self->{_problemPDL};

   foreach my $i (($self->getNoiseCutoff())..($self->getNumDataSets() - (($self->getNumTests() + 1)))) {
      my $data_pdl = $problem_pdl(:,$i);
      #print $i . "\n";
      if ( nbad($data_pdl) == 0){
         my @dataset = $data_pdl(0:$data_pdl->nelem-1)->list();
         push(@training_set,\@dataset);
      }
   }

   return @training_set;
}

sub getTestingSet {
   my ( $self ) = @_;

   my @testing_set;
   my $problem_pdl = $self->{_problemPDL};

   foreach my $i (($self->getNumDataSets() - $self->getNumTests())..($self->getNumDataSets() - $self->getForecastPeriod())) {
      my $data_pdl = $problem_pdl(:,$i);
      #print $i . "\n";
      if ( nbad($data_pdl) == 0){
         my @dataset = $data_pdl(0:$data_pdl->nelem-1)->list();
         push(@testing_set,\@dataset);
      }
   }

   return @testing_set;
}

sub getPredictionSet {
   my ( $self ) = @_;

   my @prediction_set;
   my $problem_pdl = $self->{_problemPDL};

   foreach my $i (($self->getNumDataSets() - $self->getForecastPeriod())..($self->getNumDataSets() - 1)) {
      my $data_pdl = $problem_pdl(:,$i);
      #print $i . "\n";
      if ( nbad($data_pdl) == 0){
         my @dataset = $data_pdl(0:$data_pdl->nelem-1)->list();
         push(@prediction_set,\@dataset);
      }
   }

   return @prediction_set;
}

sub createTargetGainPDL {
   my ( $self ) = @_;

   my @close = ();

   for my $date_key (@{$self->{_dateSeries}}) {
      push @close, $self->{_priceMap}->{$date_key}->getClose();
   }

   my $close_pdl = pdl(@close);

   #print "Result close_pdl         : " . $close_pdl . "\n";
   my $shifted_close_pdl = pdl $close_pdl;
   #print "Result shifted_close_pdl : " . $shifted_close_pdl;
   my $zeros = zeros($self->{_forecastPeriod});
   $shifted_close_pdl = $shifted_close_pdl->append($zeros);
   $shifted_close_pdl = $shifted_close_pdl($self->{_forecastPeriod}:$shifted_close_pdl->nelem-1);
   #print "Result shifted_close_pdl : " . $shifted_close_pdl . "\n";

   my $target_gain_pdl = ($shifted_close_pdl - $close_pdl)/$close_pdl;
   #print "Result target_gain_pdl   : " . $target_gain_pdl . "\n";

   foreach (($target_gain_pdl->nelem - $self->{_forecastPeriod}) .. $target_gain_pdl->nelem-1){
     $target_gain_pdl->index($_) .= 0;
   }

   #print "Result target_gain_pdl forecast period zeroed : " . $target_gain_pdl . "\n";

   my $average_gain = average($target_gain_pdl);
   my $max_gain = max($target_gain_pdl);
   my $max_loss = min($target_gain_pdl);

   printf ("Result Average gain = %.2f\n", $average_gain);
   printf ("Result Maximum gain = %.2f\n", $max_gain);
   printf ("Result Maximum loss = %.2f\n", $max_loss);

   #print "Result unscaled target_gain_pdl : ". $target_gain_pdl . "\n";

   foreach (0 .. $target_gain_pdl->nelem-1){
     if ($target_gain_pdl->index($_) >= $self->{_upperThreshold}){
       $target_gain_pdl->index($_) .= 1;
     }
     elsif ($target_gain_pdl->index($_) <= $self->{_lowerThreshold}){
       $target_gain_pdl->index($_) .= -1;
     }
     else{
       $target_gain_pdl->index($_) .= 0;
     }
   }

   #print "Result scaled target_gain_pdl : ". $target_gain_pdl . "\n";

   return $target_gain_pdl;
}

sub createFeaturePDL {
   my ( $self, $pricePDLSet_ref ) = @_;

   if ($pricePDLSet_ref eq "") {
      #print "createFeaturePDL  pricePDLSet not passed in so assuming that the member version is used.\n";
      $pricePDLSet = new PricePDLSet($self->{_priceMap}, $self->{_dateSeries});
      $pricePDLSet_ref = \$pricePDLSet;
   }

   my $dataPDL = pdl [];

   if($self->{_includeTimeSeries}){
      print "Result Including TimeSeries.\n";
      my $timeSeriesPDL = $self->createTimeSeriesPDL($$pricePDLSet_ref->getScaledClosePDL(), $self->{_timeSeries});
      $dataPDL = $dataPDL->glue(1,$timeSeriesPDL);
   }

   if($self->{_includeFrequencies}){
      print "Result Including Frequencies.\n";
      my $freqSeriesPDL = $self->createFreqSeriesPDL($$pricePDLSet_ref->getScaledClosePDL(), $self->{_freqSeries});
      $dataPDL = $dataPDL->glue(1,$freqSeriesPDL);
   }

   my $mfiPDL = ta_mfi($$pricePDLSet_ref->getScaledHighPDL,
                       $$pricePDLSet_ref->getScaledLowPDL,
                       $$pricePDLSet_ref->getScaledClosePDL,
                       $$pricePDLSet_ref->getScaledVolumePDL,
                        10);

   my $max_mfi = max($mfiPDL);
   $self->scale(\$mfiPDL,$max_mfi);
   $dataPDL = $dataPDL->glue(1,$mfiPDL);

   my $obvPDL = ta_obv($$pricePDLSet_ref->getScaledClosePDL,
                       $$pricePDLSet_ref->getScaledVolumePDL);

   my $max_obv = max($obvPDL);
   $self->scale(\$obvPDL,$max_obv);
   $dataPDL= $dataPDL->glue(1,$obvPDL);

   my @time_frames = (2,5,10,20,50,100,200);

   my $smaVolumePDL = $self->pdl_sma($$pricePDLSet_ref->getScaledVolumePDL,
                                     @time_frames);
   $dataPDL = $dataPDL->glue(1,$smaVolumePDL);

   my $smaClosePDL = $self->pdl_sma($pricePDLSet->getScaledClosePDL,
                                      @time_frames);
   $dataPDL = $dataPDL->glue(1,$smaClosePDL);

   my $rocPDL = $self->pdl_roc($$pricePDLSet_ref->getScaledClosePDL,
                               @time_frames);
   $dataPDL = $dataPDL->glue(1,$rocPDL);

   my $linearRegPDL = $self->pdl_linearreg($$pricePDLSet_ref->getScaledClosePDL,
                                           @time_frames);
   $dataPDL = $dataPDL->glue(1,$linearRegPDL);

   return $dataPDL;
}

sub createTimeSeriesPDL {

  my ($self, $pdl_ref, $timePeriod) = @_;

  #print "createTimeSeriesPDL\n";

  my $tempPDL = zeros($timePeriod);
  $tempPDL = $tempPDL->append($pdl_ref);

  my $timeSeriesPDL = pdl [];

  foreach (0 .. ($pdl_ref->nelem -1)){
    #print $_ . "\n";
    $timeSeriesPDL = $timeSeriesPDL->glue(1,$tempPDL($_:$_+$timePeriod)->sever);
    #print $timeSeriesPDL . "\n";
  }

  #my @dims = $timeSeriesPDL->dims;
  #print "Dims " . @dims . " : " . $dims[0] . " " . $dims[1] . "\n";

  my $scaledTimeSeriesPDL = pdl [];

  foreach (0 .. $timeSeriesPDL->getdim(1)-1){
    my $singleTimeSeriesPDL = $timeSeriesPDL(:,$_);
    my $max = max($singleTimeSeriesPDL);
    $self->scale (\$singleTimeSeriesPDL,$max);
    #print $singleTimeSeriesPDL . "\n";
    $scaledTimeSeriesPDL = $scaledTimeSeriesPDL->glue(1,$singleTimeSeriesPDL);
  }

  # FIXME Not 100% on whether it is one transpose or three.
  #       At some point do this by hand to find out.
  $scaledTimeSeriesPDL = transpose $scaledTimeSeriesPDL;

  return $scaledTimeSeriesPDL;
}

sub createFreqSeriesPDL {

  my ($self, $pdl_ref, $timePeriod) = @_;

  #print "createFreqSeriesPDL\n";
  #print $pdl_ref . "\n";

  my $tempPDL = zeros($timePeriod);
  $tempPDL = $tempPDL->append($pdl_ref);

  my $timeSeriesPDL = pdl [];

  foreach (0 .. ($pdl_ref->nelem -1)){
    #print $_ . "\n";
    $timeSeriesPDL = $timeSeriesPDL->glue(1,$tempPDL($_:$_+$timePeriod)->sever);
    #print $timeSeriesPDL . "\n";
  }

  #my @dims = $timeSeriesPDL->dims;
  #print "Dims " . @dims . " : " . $dims[0] . " " . $dims[1] . "\n";

  my $scaledTimeSeriesPDL = pdl [];

  foreach (0 .. $timeSeriesPDL->getdim(1)-1){

    my $singleTimeSeriesPDL = $timeSeriesPDL(:,$_);

    #print $singleTimeSeriesPDL . "\n";
    my $imagPDL = $singleTimeSeriesPDL * 0;

    # FIXME This is returning -ve frequencies. Is this valid?
    fftnd $singleTimeSeriesPDL, $imagPDL;

    my $max = max($singleTimeSeriesPDL);
    $self->scale (\$singleTimeSeriesPDL,$max);
    #print "Freq : \n" . $singleTimeSeriesPDL . "\n";
    $scaledTimeSeriesPDL = $scaledTimeSeriesPDL->glue(1,$singleTimeSeriesPDL);
  }

  # FIXME Not 100% on whether it is one transpose or three.
  #       At some point do this by hand to find out.
  $scaledTimeSeriesPDL = transpose $scaledTimeSeriesPDL;

  return $scaledTimeSeriesPDL;
}

sub createFXPDL {

  my ( $self ) = @_;

  my @time_frames = (2,5,10,20,50,100,200);
  my @currancies = ("USD","TWI","CNY","JPY","EUR","GBP","BTC");
  my $data_pdl = pdl[];

  foreach my $currancyKey (@currancies) {

    my @currancy = ();
    my $prev = 0;

    print "Result Adding $currancyKey features.\n";

    foreach my $dateKey (@{$self->{_dateSeries}}) {
      if (!defined $self->{_FXAUDMap}{$dateKey}->{$currancyKey}){
        print "Result $dateKey NOT DEFINED so using previous.\n";
        push @currancy, $prev;
      }
      else{
        #print $dateKey . " " . $self->{_FXAUDMap}{$dateKey}->{$currancyKey} . "\n";
        push @currancy, $self->{_FXAUDMap}{$dateKey}->{$currancyKey};
        $prev = $self->{_FXAUDMap}{$dateKey}->{$currancyKey};
      }
    }

    #print @currancy . "  -> " . $currancy[1] . "\n";

    # I do not actually include the scaled series in the feature set. Should I?
    my $currancy_pdl = pdl(@currancy);

    #print "currancy_pdl : ";
    #print $currancy_pdl . "\n";

    my $maxPrice = max($currancy_pdl);
    $self->scale(\$currancy_pdl,$maxPrice);

    #print "currancy_pdl scaled : ";
    #print $currancy_pdl . "\n";

    my $sma_pdl = $self->pdl_sma($currancy_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$sma_pdl);
    #print "Result SMA pdl : " . $sma_pdl . "\n";
    #print "Result datapdl : " . $data_pdl . "\n";

    my $roc_pdl = $self->pdl_roc($currancy_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$roc_pdl);

    my $linearreg_pdl = $self->pdl_linearreg($currancy_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$linearreg_pdl);

  }
  #print $data_pdl;
  #exit;

  return $data_pdl;
}

sub createETFsPDL {

  my ( $self ) = @_;

  my @time_frames = (2,5,10,20,50,100,200);
  my @ETFs = ("OOO","QAG","QCB","RCB","QAU","QFN","QOZ","QUAL","NDQ");
  #my @ETFs = ("GOLD","QCB","OOO","IAA","IVV","IOO","IXI","IAF","VLC");
  my $data_pdl = pdl[];

  foreach my $ETFKey (@ETFs) {

    my @ETF = ();
    my $prev = 0;

    print "Result Adding $ETFKey features.\n";

    foreach my $dateKey (@{$self->{_dateSeries}}) {
      if (!defined $self->{_ETFMap}{$dateKey}->{$ETFKey}){
        print "Result $dateKey NOT DEFINED so using previous.\n";
        push @ETF, $prev;
      }
      else{
        #print $dateKey . " " . $self->{_ETFMap}{$dateKey}->{$ETFKey} . "\n";
        push @ETF, $self->{_ETFMap}{$dateKey}->{$ETFKey};
        $prev = $self->{_ETFMap}{$dateKey}->{$ETFKey};
      }
    }

    #print @ETF . "  -> " . $ETF[1] . "\n";

    # I do not actually include the scaled series in the feature set. Should I?
    my $ETF_pdl = pdl(@ETF);

    #print "ETF_pdl : ";
    #print $ETF_pdl . "\n";

    my $maxPrice = max($ETF_pdl);
    $self->scale(\$ETF_pdl,$maxPrice);

    #print "ETF_pdl scaled : ";
    #print $ETF_pdl . "\n";

    my $sma_pdl = $self->pdl_sma($ETF_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$sma_pdl);
    #print "Result SMA pdl : " . $sma_pdl . "\n";
    #print "Result datapdl : " . $data_pdl . "\n";

    my $roc_pdl = $self->pdl_roc($ETF_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$roc_pdl);

    my $linearreg_pdl = $self->pdl_linearreg($ETF_pdl,@time_frames);
    $data_pdl = $data_pdl->glue(1,$linearreg_pdl);

  }
  #print $data_pdl;
  #exit;

  return $data_pdl;
}



sub createDaysMonthsPDL {

  my ( $self ) = @_;

  my $data_pdl = pdl[];

  foreach my $dateKey (@{$self->{_dateSeries}}) {

     #print "\n$dateKey ";

     my $t = Time::Piece->strptime($dateKey, "%Y-%m-%d");
     my @dayDataset = (0,0,0,0,0,0,0);
     $dayDataset[$t->_wday] = 1;
     my @monthDataset = (0,0,0,0,0,0,0,0,0,0,0,0);
     $monthDataset[$t->_mon] = 1;
     push @monthDataset, @dayDataset;
     my $day_month_pdl = pdl(@monthDataset);
     #print $day_month_pdl;
     $data_pdl = $data_pdl->glue(1,$day_month_pdl);
  }

  $data_pdl = transpose $data_pdl;

  return $data_pdl;
}

sub scale {

  my ($self, $pdl_ref, $max) = @_;

  #print "max = " . $max . "\n";

  if ($max ne 0){
    $$pdl_ref = $$pdl_ref/$max;
  }
  #print "Result After scalling : " . $$pdl_ref . "\n";
}

sub pdl_roc {
  my ($self, $pdl_ref, @sample_periods) = @_;
  my $series_pdl = pdl [];

  foreach my $sample_period (@sample_periods) {
     #print "$sample_period \n";
     my $pdl = ta_roc($pdl_ref, $sample_period);
     # Need to scale the answer as the ROC can be far greater than 1.
     my $max = max($pdl);
     #FIXME Why doesn't this work?
     #$self->scale(\$pdl,$max);
     $pdl = $pdl/$max;
     #####
     #print "Result ROC pdl : " . $pdl . "\n";
     $series_pdl = $series_pdl->glue(1,$pdl);
  }
  return $series_pdl;
}

sub pdl_sma {
  my ($self, $pdl_ref, @sample_periods) = @_;
  my $series_pdl = pdl [];

  foreach my $sample_period (@sample_periods) {
     #print "$sample_period \n";
     my $pdl = ta_sma($pdl_ref, $sample_period);
     #print "Result SMA pdl : " . $pdl . "\n";
     $series_pdl = $series_pdl->glue(1,$pdl);
  }
  return $series_pdl;
}

sub pdl_linearreg{
  my ($self, $pdl_ref, @sample_periods) = @_;
  my $series_pdl = pdl [];

  foreach my $sample_period (@sample_periods) {
     #print "$sample_period \n";
     my $pdl = ta_linearreg($pdl_ref, $sample_period);
     #print "Result Linear Regression pdl : " . $pdl . "\n";
     $series_pdl = $series_pdl->glue(1,$pdl);
  }
  return $series_pdl;
}

sub printClose {
   my ( $self ) = @_;

   my $closing_price = $self->{_priceMap}->{$self->{_finalDate}}->getClose();
   print "Result Closing price for $self->{_finalDate} : $closing_price\n";

}

sub getOpen {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getOpen();

}

sub getHigh {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getHigh();

}

sub getLow {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getLow();

}

sub getClose {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getClose();

}

sub getVolume {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getVolume();

}

sub getAdjClose {
   my ( $self, $date ) = @_;

   return $self->{_priceMap}->{$date}->getAdjClose();

}
1;
