#!/usr/bin/perl
$|++;

use strict;
use warnings;

# NB: The '$|++;' stmt above tells perl to flush all output to stdout
# as soon as it's generated rather than waiting till the output buffer
# fills up.  Without it, CLI output redirection to files didn't seem
# to work.

# bduffy@carleton.edu 2014-04-29: This code consumes lines generated
# by ENTS262-DAQ-v2.pl, which start with a header row followed by any
# number of data rows like so:
#
#     timestamp, epochseconds, V1, V2, V3, C1, C2, C3, C4, Sun
#     Tue Feb  5 10:01:15 2013, 1360080075, 4.812, -0.000, -0.000, 20.93725, 20.95904, 20.96530, 1.05776, 0.16053
#
# ... and emits a line that summarizes the data from every $maxLine lines
# (15 minutes) with the following format:
#
#     datetime, epochseconds, L1, L2, L3, C1, C2, C3, C4, Sun, eventdensity
# 
# Where:
#
#     'datetime' is the date and time at the end of the interval.
#
#     'epochseconds' is the epochseconds at the end of the interval.
#  
#     'L1', 'L2', 'L3' is the number of lines the DAQ reported each
#     lamp was on for each experiment.
#
#     'C1', 'C2', 'C3' are the averages of the temperatures reported
#     by the DAQ controller for each experiment.
#
#     'C4' is the average of the outside temperatures reported by the
#     DAQ controller.
#
#     'Sun' is the average insolation (cryptically encoded)
#
#     'eventdensity' is the ratio of actual logged events (lines in the
#      raw .csv file) in the interval over the total possible events,
#      assuming a rate of 1 event per second.  So if the interval is
#      15 minutes (900 seconds) and 900 events (lines in the raw .csv
#      file) exist and were processed by this script in that 15 minute
#      interval, then the 'eventdensity' would be 1.0.  If only 450
#      events (lines in the raw .csv file) were present for the
#      interval, the eventdensity value would be 0.5
#
#
# For each of the input lines, L1, L2, L3 is considered 'on' if the
# reported voltage in the input line (V1, V2, V3) is higher than the
# threshold voltage, currently set to 2.0v.
#
#
# Events (lines in the raw csv file) are summarized over 15 minute intervals
# starting at 0, 15, 30, and 45 minutes on the clock.  This means the 1st and
# last summary lines could have very low 'eventdensity' values.
#


my $debugFlag = 0;
my $debugGaps = 0;
my $text;
my @curValAr;

my $V1Count = 0;
my $V2Count = 0;
my $V3Count = 0;

my $C1Sum = 0.0;
my $C2Sum = 0.0;
my $C3Sum = 0.0;
my $C4Sum = 0.0;

my $SunSum = 0.0;

my $transitionVoltage = 2.0;
my $intervalLinesRead = 0;
my $maxLines = 900;

my $intervalSize = 900;
my $prevEpochSecond = 0;
my $curEpochSecond = 0;
my $modEpochSeconds = 0;
my $prevIntervalEpochSecond = 0;
my $nextIntervalEpochSecond = 0;

print "\ndatetime, epochseconds, L1, L2, L3, C1, C2, C3, C4, Sun, eventdensity";

while ($text = <STDIN>) {

    #remove newline
    chomp($text);

    # stop when we get an empty line
    last if ($text eq '');

    # Remove the space characters that immediately follow the commas in
    # the csv formatted line so that when we call split() below, we get
    # array values that can be interpreted as numbers.
    $text =~ s/, /,/g;

    # Break the line into array elements, using ',' as the field
    # separator.  V1 = @curValAr[2], V2 = @curValAr[3], V3 =
    # @curValAr[4], etc.
    @curValAr = split(/,/, $text);

    if ( $debugFlag ) {
	print "\n---------------------------------------------------";
	print "\nDEBUG: \$text='$text'";
	print "\nDEBUG: $V1Count, $V2Count, $V3Count, $C1Sum, $C2Sum, $C3Sum, $C4Sum, $SunSum";
    }

    # In rare cases, we get a digest line with empty instrument value
    # fields that looks like this:
    #   'Thu Feb 27 10:34:34 2014, 1393518874, , , , , , , ,'
    # ...which when parsed means that $curValAr[2,3,4,5,6,7,8,9] are out of bounds.
    # Skip such lines.
    #
    if ( 0+@curValAr  < 3 ) {
	printf ("\nDEBUG: NO DATA near %d.  \$curValArray size = %d", $prevEpochSecond, (0+@curValAr) ) if ( $debugGaps );
	next;
    }

    # Ignore the header line
    next if ($curValAr[2] eq "V1");


    $curEpochSecond = $curValAr[1];
    if ( $debugFlag ) {
	printf("\nDEBUG: \$curEpochSecond = %d | %s \nDEBUG: \$nextIntervalEpochSecond %d | %s",
	       $curEpochSecond, scalar localtime($curEpochSecond),
	       $nextIntervalEpochSecond, scalar localtime($nextIntervalEpochSecond),
	    );
    }
    if ( $debugGaps ) {
	if ( $prevEpochSecond != 0 && (($prevEpochSecond + 1) != $curEpochSecond) ) {
	    print "\nDEBUG: GAP at $prevEpochSecond";
	}
    }
    $prevEpochSecond = $curEpochSecond;


    # Calculate $nextIntervalEpochSecond, the last epoch second for this interval
    if ( $nextIntervalEpochSecond == 0 ) {
	$modEpochSeconds = $curEpochSecond % $intervalSize;
	$prevIntervalEpochSecond = $curEpochSecond - $modEpochSeconds;
	$nextIntervalEpochSecond = $prevIntervalEpochSecond + $intervalSize; 

	if ( $debugFlag ) {
	    printf("\nDEBUG: \$nextIntervalEpochSecond %d | %s \nDEBUG: \$prevIntervalEpochSecond %d | %s \nDEBUG: \$nextIntervalEpochSecond %d | %s",
		   $nextIntervalEpochSecond, scalar localtime($nextIntervalEpochSecond),
		   $prevIntervalEpochSecond, scalar localtime($prevIntervalEpochSecond),
		   $nextIntervalEpochSecond, scalar localtime($nextIntervalEpochSecond)
		);
        }
    }

    while ( $curEpochSecond >= $nextIntervalEpochSecond ) {

	# Print summary line for this interval.  Because multiple
	# intervals could be skipped from one input event to the next,
	# this while loop could print multiple empty interval lines.
	#
	printIntervalSummary ($intervalLinesRead,  $intervalSize,
			      $nextIntervalEpochSecond,
			      $V1Count, $V2Count, $V3Count,
			      $C1Sum, $C2Sum, $C3Sum,  $C4Sum,  $SunSum,);

	if ( $intervalLinesRead > 0 ) {
	    # Reset counters for next iteration
	    $intervalLinesRead = 0;
	    $V1Count = $V2Count = $V3Count = 0;
	    $C1Sum = $C2Sum = $C3Sum = $C4Sum = $SunSum = 0.0;
	}

	$nextIntervalEpochSecond += $intervalSize;
	if ( $debugFlag ) {
	    printf("\nDEBUG: \$nextIntervalEpochSecond %d | %s",
		   $nextIntervalEpochSecond, scalar localtime($nextIntervalEpochSecond)
		);
	}
    }

    # Accumulate counters
    $intervalLinesRead++;
    $V1Count += 1 if ( $curValAr[2] > $transitionVoltage);
    $V2Count += 1 if ( $curValAr[3] > $transitionVoltage);
    $V3Count += 1 if ( $curValAr[4] > $transitionVoltage);

    $C1Sum += $curValAr[5];
    $C2Sum += $curValAr[6];
    $C3Sum += $curValAr[7];
    $C4Sum += $curValAr[8];
    $SunSum += $curValAr[9];

    if ( $debugFlag ) {
	printf("\nDEBUG: Accumulated Values: %d, %d, %d, %.5f, %.5f, %.5f, %.5f, %.5f, %d/%d", 
	       $V1Count, $V2Count, $V3Count, $C1Sum, $C2Sum, $C3Sum, $C4Sum, $SunSum, $intervalLinesRead, $intervalSize
	);
    }
}

# We've hit the end of the input file.  Print last intervalSummary
# line if there's accumulated data (almost always)
if ( $intervalLinesRead > 0 ) {
    printIntervalSummary ($intervalLinesRead,  $intervalSize,
			  $nextIntervalEpochSecond,
			  $V1Count, $V2Count, $V3Count,
			  $C1Sum, $C2Sum, $C3Sum,  $C4Sum,  $SunSum,);
}


print "\n";

exit 1;


sub printIntervalSummary {
    ($intervalLinesRead,  $intervalSize,
     $nextIntervalEpochSecond,
     $V1Count, $V2Count, $V3Count,
     $C1Sum, $C2Sum, $C3Sum,  $C4Sum,  $SunSum,
    ) = @_;

    my($C1Avg) = 0.0;
    my($C2Avg) = 0.0;
    my($C3Avg) = 0.0;
    my($C4Avg) = 0.0;
    my($SunAvg) = 0.0;

    if ( $intervalLinesRead > 0 ) {
	$C1Avg =  ($C1Sum/$intervalLinesRead);
	$C2Avg =  ($C2Sum/$intervalLinesRead);
	$C3Avg =  ($C3Sum/$intervalLinesRead);
	$C4Avg =  ($C4Sum/$intervalLinesRead);
	$SunAvg = ($SunSum/$intervalLinesRead);
    }

    printf("\n%s, %s, %d, %d, %d, %.5f, %.5f, %.5f, %.5f, %.5f, %d/%d",
	   scalar localtime($nextIntervalEpochSecond),
	   $nextIntervalEpochSecond,
	   $V1Count, $V2Count, $V3Count,
	   $C1Avg, $C2Avg, $C3Avg, $C4Avg, $SunAvg,
	   $intervalLinesRead, $intervalSize,
	);
}









