#!/bin/sh -x


for F in ./Digests/*-digest.csv
do
#    echo $F
    DF=`dirname $F`/`basename $F .csv`-summary.csv
#    echo $DF
    /usr/bin/perl ENTS262-DAQ-Summarize-Digest2.pl < $F > $DF
done