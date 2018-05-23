#!/bin/sh

SECONDS=51000
DIGESTDIR="/root/insolation/Digests-2015"
DIGESTFILE="${DIGESTDIR}/`date "+%Y-%m-%d-digest.csv"`"
DIGESTERRFILE="${DIGESTDIR}/`date "+%Y-%m-%d-digest.err"`"
DIGESTSUMMARYFILE="${DIGESTDIR}/`date "+%Y-%m-%d-digest-summary.csv"`"

# bduffy 2015-02-02: The '-v+1d' part of the date command from osx doesn't
# work under Centos6
#DIGESTFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest.csv"`"
#DIGESTERRFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest.err"`"
#DIGESTSUMMARYFILE="${DIGESTDIR}/`date -v+1d "+%Y-%m-%d-digest-summary.csv"`"

# Neither of these file perm tricks seem to work with the COURSES volume...
umask 0033
/bin/touch ${DIGESTFILE}; /bin/touch ${DIGESTSUMMARYFILE}
/bin/chmod 644 ${DIGESTFILE}; /bin/chmod 644 ${DIGESTSUMMARYFILE}; 

/usr/bin/perl /root/insolation/ENTS262-DAQ-Digest-v2.pl ${SECONDS} 2> ${DIGESTERRFILE} | tee ${DIGESTFILE} | /usr/bin/perl /root/insolation/ENTS262-DAQ-Summarize-Digest-v2.pl > ${DIGESTSUMMARYFILE}

exit 0
