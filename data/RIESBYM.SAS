OPTIONS NOCENTER;
TITLE1 'Analysis of Riesby data - HDRS scores across time';

DATA ONE;
  INFILE 'C:\mixdemo\RIESBY.DAT';
  INPUT ID HamD Intcpt Week Endog EndWeek ;

PROC FORMAT;
     VALUE Endog 0='NonEndog' 1='Endog';
     VALUE Week  0='week 0'   1='week 1'   2='week 2'
                 3='week 3'   4='week 4'   5='week 5';

PROC MIXED METHOD=ML COVTEST;
  CLASS ID;
  MODEL HAMD = WEEK /SOLUTION;
  RANDOM INTERCEPT  /SUB=ID TYPE=UN G;
  TITLE2 'Random intercepts model: compound symmetry structure';

PROC MIXED METHOD=ML COVTEST;
  CLASS ID;
  MODEL HAMD = WEEK /SOLUTION;
  RANDOM INTERCEPT WEEK /SUB=ID TYPE=UN G GCORR;
  TITLE2 'Random trend model';

PROC MIXED METHOD=ML COVTEST;
  CLASS ID;
  MODEL HAMD = WEEK ENDOG ENDWEEK /SOLUTION;
  RANDOM INTERCEPT WEEK /SUB=ID TYPE=UN G GCORR;
  TITLE2 'Random trend model with group effects';

PROC MIXED METHOD=ML COVTEST;
  CLASS ID;
  MODEL HAMD = WEEK WEEK*WEEK /SOLUTION;
  RANDOM INTERCEPT WEEK WEEK*WEEK /SUB=ID TYPE=UN G GCORR;
  TITLE2 'Random quadratic trend model';

RUN;
