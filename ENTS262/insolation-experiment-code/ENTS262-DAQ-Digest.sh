#!/bin/sh

SECONDS=87000
#DIGESTDIR="/Volumes/COURSES/ents262-00-w13/Common"
DIGESTDIR="/Users/phasadmin/ENTS262/Digests"
DIGESTFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest.csv"`"
DIGESTERRFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest.err"`"
DIGESTSUMMARYFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest-summary.csv"`"

# Neither of these file perm tricks seem to work with the COURSES volume...
umask 0033
/usr/bin/touch ${DIGESTFILE}; /usr/bin/touch ${DIGESTSUMMARYFILE}
/bin/chmod 644 ${DIGESTFILE}; /bin/chmod 644 ${DIGESTSUMMARYFILE}; 

cd `dirname $0`
/usr/bin/perl ./ENTS262-DAQ-Digest-v2.pl ${SECONDS} 2> ${DIGESTERRFILE} | tee ${DIGESTFILE} | /usr/bin/perl ./ENTS262-DAQ-Summarize-Digest-v2.pl > ${DIGESTSUMMARYFILE}
exit 0
