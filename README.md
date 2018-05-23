Insolation experiment readme - Max Trostel and Bruce Duffy - May 22, 2018

The code and documentation for this experiment can be found in the code+docs folder, as a python file, insolation.py
A description for how this would be used in an academic context can be found in the document created by Joel Weisberg,
called PS7Energy20140528.docx. A sample set of data can be found in the file "Insolation.i_3.d_0.5.2018-05-21_09-53-45.csv".
Additional info from correspondences with Tom and Melissa can also be found in this folder.


A short description header for the code:

Insolation experiment - Max Trostel and Bruce Duffy - May 16, 2018
This program gets and writes data from the  insolation experiment, a set of three insulated boxes, each
containing a 60 W incandescent lightbulb which heats the box when the temperature falls below
20 C. Box 1 has an insulation value of R=3, Box 2 R=5 with window, Box 3 R=5
w/o window. The boxes are placed outside in winter to test these insulation
values The data collected by the exeriment and retrieved by this code comes
in as follows:
Time/Date, Epoch Time (s), Box 1 Lightbulb (V), Box 2 Lightbulb (V), Box
1 Lightbulb (V), Box 1 Temp (C), Box 2 Temp (C), Box 3 Temp (C), Outside Temp
(C), and Insolation/910 (W/m^2).

Further details can be found in documents accompanying this code, and in the
--help ussage.

