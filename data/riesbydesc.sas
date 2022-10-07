* Descriptive statistics for Riesby dataset;

DATA one;
  INFILE 'c:\SAS_long\RIESBY.DAT.txt';
  INPUT id HamD Intcpt Week Endog EndWeek ;

PROC FORMAT;
     VALUE Endog 0='NonEndog' 1='Endog';
     VALUE Week  0='week 0'   1='week 1'   2='week 2'
                 3='week 3'   4='week 4'   5='week 5';

* Descriptives;
PROC MEANS;
RUN;

* get the data in multivariate format for a matrix plot;
PROC SORT; BY id;RUN;     
DATA t0;SET one; IF week=0; hamd_0 = hamd; RUN;
DATA t1;SET one; IF week=1; hamd_1 = hamd; RUN;
DATA t2;SET one; IF week=2; hamd_2 = hamd; RUN;
DATA t3;SET one; IF week=3; hamd_3 = hamd; RUN;
DATA t4;SET one; IF week=4; hamd_4 = hamd; RUN;
DATA t5;SET one; IF week=5; hamd_5 = hamd; RUN;
DATA comp (KEEP=id hamd_0-hamd_5 Endog);
     MERGE t0 t1 t2 t3 t4 t5; BY id;
RUN;

* get a sorted dataset by group;
DATA SortData;
     SET comp;
PROC SORT;
BY Endog;
RUN;

* Descriptives across time by group;
PROC MEANS DATA=SortData;
VAR hamd_0-hamd_5;
BY Endog; FORMAT Endog Endog. ; 
RUN;

* Pairwise deleted correlation matrix;
PROC CORR DATA=comp;
VAR hamd_0-hamd_5;
RUN;

* Listwise deleted correlation matrix;
PROC CORR NOMISS DATA=comp;
VAR hamd_0-hamd_5;
RUN;
