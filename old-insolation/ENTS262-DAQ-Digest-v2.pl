#!/usr/bin/perl

use IO::Handle;
STDERR->autoflush(1);
STDOUT->autoflush(1);

use strict;
use warnings;

# NB: The '$|++;' stmt above tells perl to flush all output to stdout
# as soon as it's generated rather than waiting till the output buffer
# fills up.  Without it, CLI output redirection to files didn't seem
# to work.

# bduffy@carleton.edu 2013-01-25: 
#
# This script is inspired by the sample code provided by the
# manufacturer, located here:
#
#    http://www.controlbyweb.com/temperature/perl-daq-temperature.zip
#
# It pulls data from the Xytronix Research & Design, Inc. "DAQ Series
# Analog Module" by talking to it's onboard http server and requesting
# it's 'state.xml' file, which has a format like:
#
# <?xml version="1.0" encoding="utf-8"?>
# <datavalues>
#   <input0state>dd.dd volt</input0state>
#   <input1state>dd.dd volt</input1state>
#   <input2state>dd.dd volt</input2state>
#   <input3state>dd.ddddd C</input3state>
#   <input4state>dd.ddddd C</input4state>
#   <input5state>dd.ddddd C</input5state>
#   <input6state>dd.ddddd C</input6state>
#   <input7state>dd.ddddd sun</input7state>
#   <powerupflag>1</powerupflag>
# <datavalues>
#
# It then pulls the numeric content from the child elems of the
# '<datavalues> elem and prints one line of csv output.
#
# By default, the script polls the daq module just once, but that can
# be changed by supplying an optional iteration count on the command
# line.  The DAQ module updates 1/s, so we pause 1s between
# iterations, meaning the script runs for the number of seconds
# specified by the iteration count.
#
# The script is intended to be called from a *nix command line like
# so:
#
#     perl ./ents-262-daq.pl 1000 > ents-data.csv
#
# NB: You can also see the real-time values the DAQ unit publishes by
# pointing you browser here:
#
#     http://ents-262-daq.physics.carleton.edu/
#
# CAVEATS:
# 
# 1. No provision is made for error handling.  There are many ways
#    this code could fail.  They are identified by the 'XXX:' substrs
#    embedded in the code.  Basically if an error occurs in any
#    iteration, the script fails at the point.
#
# 2. Gaps in the csv output could occur (detectable by differences in
#    'epochseconds' > 1 from one row to the next) if the client or
#    server aren't running optimally.
# 
# 3. Client and server clocks are not synchronized: Because the server
#    updates 1/s, and the client calls it 1/s, and the client and
#    server clocks are not synchronized. it's possible the client can
#    double-report update N while missing update N+1.  This could be
#    worked around by polling more than 1/s, and not emitting the data
#    if the result was the same -- however it's probably legit for one
#    iteration's values to be identical to the next iterations values.
#    Overpolling would work if the server reported it's clock
#    epochseconds, but it doesn't so I'm not going to worry about it.



my $debugFlag = 0;
my $UnitAddr = "137.22.6.220";
# my $UnitAddr = "insolation.physics.carleton.edu";

my $iterations = 1;

if( $ARGV[0] )
{
	$iterations = $ARGV[0];
}
if ( $debugFlag ) { print "\niterations=\"".$iterations."\"\n"; }

use IO::Socket::INET;
use Time::HiRes qw (sleep alarm);

# NB: If the daq module's data access password is set, 'get_state_msg'
# must be changed to include the base64 encoding of username/password.
# See Section 3.3 "GET Requests" in the online manual located here:
#
#     http://www.controlbyweb.com/analog/analog_manual_v1.1.pdf
#
my $get_state_msg="GET /state.xml HTTP/1.1\r\nAuthorization: Basic bm9uZTp3ZWJyZWxheQ==\r\n\r\n";

printf "timestamp, epochseconds, V1, V2, V3, C1, C2, C3, C4, Sun\n";

while ( $iterations-- ) {

    # Wrap everything in an eval so that we don't drop out of the script until
    # we done all our iterations.
    my $status = eval {

	if ( $debugFlag ) { print "\niterations=\"".$iterations."\"\n"; }

	# XXX Should handle fail to open socket and enforce a very short timeout value
	# (< 1 second?), so that fail to connect doesn't mess up multi-iteration runs
	#
	# What form should error output take?  Could add a new success 0|1
	# field, or just negative values for the reported voltage.
	# Another way would be to omit the line for that iteration
	# entirely.
	#
	#
	local $SIG{ALRM} = sub { die 'Timed Out'; };
	Time::HiRes::alarm (1.0); # timeout value

	my $mySocket=new IO::Socket::INET(
	    PeerAddr=>$UnitAddr,
	    PeerPort=>80,
	    Proto=>'tcp',
	    Timeout => 2
	    );

	my $text;
	my $offset = 0;
	my $valStartIndex = 0;
	my $valEndIndex = 0;
	my $valEndSpaceIndex = 0;
	my $valLen = 0;
	my @valAr;
	my $count = 0;

	if ( $debugFlag ) { print "\nSending message: \n".$get_state_msg; }
	# XXX: Error handling needed here
	$mySocket->send($get_state_msg);
	# XXX: Error handling needed here
	$mySocket->recv($text,1000);
	if ( $debugFlag ) { print "\nReceived message: \n".$text."\n"; }
	$mySocket->close();
	Time::HiRes::alarm (0.0);

	$valAr[0] = localtime(time());
	$valAr[1] = time();

	# XXX: Error handling needed here -- received text may not be what we're expecting
	#
	$offset = index($text, '>', $offset) + 1;

	for ($count = 2; $count < 10; $count++ ) {
	    $offset = index($text, '>', $offset) + 1;
	    $offset = index($text, '>', $offset);
	    $valStartIndex = $offset+1;
	    $valEndIndex = index($text, '<', $valStartIndex);
	    $valLen = $valEndIndex - $valStartIndex;

	    # Omit non-numeric parts of the value that may follow the
	    # numeric part, beginning with the first ' ' character.
	    $valEndSpaceIndex = index($text, ' ', $valStartIndex);
	    if ( $valEndSpaceIndex > 0 && ($valEndSpaceIndex < $valEndIndex) )
	    {
		$valLen = $valEndSpaceIndex - $valStartIndex;
	    }

	    $offset = $valEndIndex + 2;

	    if ( $debugFlag ) { print "\nvalStartIndex=\"".$valStartIndex.", valEndIndex=\"".$valEndIndex."\n"; }

	    $valAr[$count] = substr $text, $valStartIndex, $valLen;
	    if ( $debugFlag ) { print "\nvalAr[".$count."]=\"".$valAr[$count]."\"\n"; }
	}

	{
	local $" = ', ';
	print "@valAr\n";
	}


    }; # eval
    Time::HiRes::alarm (0.0); # race condition protection.  NOTE:
			      # hires sleep an alarm use same
			      # underlying timer)
    warn localtime(time())." Error: Eval corrupted: $@" if $@;
    # Call the high-precision sleep()
    Time::HiRes::sleep (1.0);

} #while 

exit 1;











