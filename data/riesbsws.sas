TITLE1 'partitioning BS and WS effects of drug levels';
DATA one; INFILE 'c:\mixdemo\riesbyt4.dat';
INPUT id hamdelt intcpt week sex endog lnimi lndmi;

PROC SORT; BY id;
PROC MEANS NOPRINT; CLASS id; VAR lnimi lndmi;
OUTPUT OUT = two MEAN = mlnimi mlndmi;

DATA three; MERGE one two; BY id;
lnidev = lnimi - mlnimi;
lnddev = lndmi - mlndmi;


PROC MIXED METHOD=ML COVTEST;
  CLASS id;
  MODEL hamdelt = week lnimi lndmi /SOLUTION;
  RANDOM INTERCEPT week /SUB=id TYPE=UN G GCORR;
TITLE2 'assuming bs=ws drug effects';

PROC MIXED METHOD=ML COVTEST;
  CLASS id;
  MODEL hamdelt = week mlnimi mlndmi lnidev lnddev /SOLUTION;
  RANDOM INTERCEPT week /SUB=id TYPE=UN G GCORR;
TITLE2 'relaxing bs=ws drug effects';
RUN;
