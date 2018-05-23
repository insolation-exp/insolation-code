<?php

// hostname
define('HOSTNAME', 'http://xx.x.xx.xx:xxxx/');
// get the request
$path = $_GET['path'];

// create the whole request hostname + path
$url = HOSTNAME.$path;

// get the Curl session
$session = curl_init($url);

// set some options for curl
curl_setopt($session, CURLOPT_HEADER, false); // don't return the header
curl_setopt($session, CURLOPT_RETURNTRANSFER, true); // return the result as a string
curl_setopt($session, CURLOPT_CONNECTTIMEOUT, 3); // timeout if we don't connect after 3 seconds to the device

// send the request
$xml = curl_exec($session);

// return the result
echo $xml;

// close the curl connection
curl_close($session);
?>