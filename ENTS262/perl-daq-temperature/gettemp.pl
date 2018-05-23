# Client Program

#get command line values
my $whichOne = 1;
my $UnitAddr = "10.7.1.99"
if($ARGV[0])
{
	$UnitAddr = $ARGV[0];
}
if($ARGV[1])
{
	$whichOne = $ARGV[1];
}


use IO::Socket::INET;
#print ">> Client Program <<";

# Create a new socket
$MySocket=new IO::Socket::INET->new(PeerPort=>80,Proto=>'tcp',PeerAddr=>$UnitAddr);

# Send messages
$def_msg="GET /state.xml HTTP/1.1\r\nAuthorization: Basic bm9uZTp3ZWJyZWxheQ==\r\n\r\n";
#print "\nSending message: \n".$def_msg;
$MySocket->send($def_msg);

$MySocket->recv($text,300);
#print "\nReceived message: \n".$text;

# Get temp 1
my $index1 = index($text, '<sensor1temp>') + 13;
my $temp1 =  substr $text, $index1, 4;
#printf "Sensor1 = ".$temp1;

# Get temp 2
my $index2 = index($text, '<sensor2temp>') + 13;
my $temp2 =  substr $text, $index2, 4;
#printf "\nSensor1 = ".$temp1;

# Get temp 3
my $index3 = index($text, '<sensor3temp>') + 13;
my $temp3 =  substr $text, $index3, 4;
#printf "\nSensor1 = ".$temp1;

# Get temp 4
my $index4 = index($text, '<sensor4temp>') + 13;
my $temp4 =  substr $text, $index4, 4;
#printf "\nSensor1 = ".$temp1;

if ($whichOne eq "1") {printf $temp1."\n".$temp1."\n".time()."\nTemp Sensor 1"};
if ($whichOne eq "2") {printf $temp2."\n".$temp2."\n".time()."\nTemp Sensor 2"};
if ($whichOne eq "3") {printf $temp3."\n".$temp3."\n".time()."\nTemp Sensor 3"};
if ($whichOne eq "4") {printf $temp4."\n".$temp4."\n".time()."\nTemp Sensor 4"};

$MySocket->close();
exit 1;


