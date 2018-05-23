# Insolation experiment - Max Trostel and Bruce Duffy - May 16, 2018

# This program gets and writes data from the  insolation experiment, a set of three insulated boxes, each
# containing a 60 W incandescent lightbulb which heats the box when the temperature falls below
# 20 C. Box 1 has an insulation value of R=3, Box 2 R=5 with window, Box 3 R=5
# w/o window. The boxes are placed outside in winter to test these insulation
# values The data collected by the exeriment and retrieved by this code comes
# in as follows:
# Time/Date, Epoch Time (s), Box 1 Lightbulb (V), Box 2 Lightbulb (V), Box
# 3 Lightbulb (V), Box 1 Temp (C), Box 2 Temp (C), Box 3 Temp (C), Outside Temp
# (C), and Insolation/910 (W/m^2).

# Further details can be found in documents accompanying this code, and in the
# --help ussage.


from lxml import html
import requests
import xml.etree.ElementTree as et
from datetime import datetime
from time import time, sleep
import schedule
import csv
import sys
import readchar

# Usage statement:
use ="Usage: insolation.py --interval=<int, seconds> --duration=<real,\
 hours>\nRuns insolation experiment with parameters; writes to current\
 directory.\n\
\n   -h, --help           display this help and exit\
\n   -i, --interval       takes =<int, seconds>, i.e. an interger number of\
 seconds for the sampling interval\
\n   -d, --duration       takes =<real, hours>, i.e. a double precision float of\
 the total time of the observing run in hours\
\n\nBy default, when no arguments are given, the code runs with --interval=5\
 and --duration = 23.98. Interval cannot exceed 4000 and duration 72."

# Get parameters from command line arguments
if len(sys.argv) == 1:
    interval = 5
    dur = 23.98
    duration = int(dur*3600)
else:
    for i in range(1,len(sys.argv)):
        arg = sys.argv[i]
        try:
            pi = arg.index('=')
        except:
            pi = len(arg)
        param = arg[:pi]
        if param == '--help' or param == '-h':
            print(use)
            quit(1)
        elif param == '--interval' or param == '-i':
            try:
                interval = int(arg[pi+1:])
            except:
                print("Error: invalid interval - NaN")
                quit(1)
            if interval > 4000:
                print("Error: invalid interval - too long (>4000)")
                quit(1)
        elif param == '--duration' or param == '-d':
            try:
                dur = float(arg[pi+1:])
            except:
                print("Error: invalid duration - NaN")
                quit(1)
            if dur > 72:
                print("Error: invalid duration - too long (>72)")
                quit(1)
        else:
            print("Error: invalid argument - " + str(param) + " -  see --help for usage")
            quit(1)
    try:
        interval
    except:
        print("Error: interval not defined - see --help for usage")
        quit(1)
    try:
        dur
    except:
        print("Error: duration not defined - see --help for usage")
        quit(1)
    duration = int(dur*3600)

# Function to get data from insolation server, returns time and state data
def getstate():
    page = requests.get('http://insolation.physics.carleton.edu/stateFull.xml')
    root = et.fromstring(page.content)
    state = [datetime.now().strftime('%Y-%m-%d_%H-%M-%S'), str(int(time())),
            str(float(root[0].text)), str(float(root[1].text)), str(float(root[2].text)),
            str(float(root[3].text)), str(float(root[4].text)), str(float(root[5].text)),
            str(float(root[6].text)), str(float(root[7].text))]
    return state

# Record start time of experiment run
try:
    starttime = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    startepoch = int(time())
except:
    print("Error: cannot get system time.")
    quit(1)

# Header to be written to the CSV file
header = [["Date/Time","Epoch","V1","V2","V3","T1","T2","T3","T4","Sol","FailureCount"]]

# Create and open new csv, named by argument parameters and  start date/time
try:
    myFile = open('Insolation.i_' + str(interval) + '.d_' + str(dur) + '.' + starttime + '.csv', 'w')
except:
    print("Error: cannot open data file.")
    quit(1)

# Begin error count at 0
ecount = 0

# Begin writing to CSV file, starting with header, followed by state data
with myFile:
    writer = csv.writer(myFile)
    writer.writerows(header)
    # Get data, write to csv row
    def job():
        global ecount
        t = round((time() - startepoch)/3600, 4)
        try:
            dat = getstate()
            newData = [dat + [str(ecount)]]
            ecount = 0
            print("State retrieval successful... " + str(t) + "/" + str(dur) + "hours")
            try:
                writer.writerows(newData)
            except:
                print("Error: cannot write to data file.")
                quit(1)
        except:
            ecount = ecount + 1
            print("Error: state retrieval failed... " + str(t) + "/" + str(dur) +
                  "hours")
        if (int(time()) > int(startepoch + duration)):
            print("Observing run complete.")
            return quit()

    # Schedule new data retrieval/writing at specified interval
    schedule.every(interval).seconds.do(job)

    while True:
        schedule.run_pending()
        sleep(1)
