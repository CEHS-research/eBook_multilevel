OPTIONS NOCENTER LINESIZE=81 PAGESIZE=66;
TITLE1 'Random-effects analysis of NIMH Schizophrenia longitudinal data';
DATA ONE; INFILE 'C:\MIXDEMO\SCHIZREP.DAT';
     INPUT ID IMPS79 WEEK DRUG SEX ;

/* The coding for the variables is as follows:
   ID     = subject ID number
   IMPS79 = overall severity (1=normal, ..., 7=among the most extremely ill)
   WEEK   = 0,1,2,3,4,5,6 (most of the obs. are at weeks 0,1,3, and 6)
   DRUG     0=placebo  1=drug (chlorpromazine, fluphenazine, or thioridazine)
   SEX      0=female   1=male
*/

/* compute the square root of week to linearize relationship */
SWEEK = SQRT(WEEK);

/* calculate the maximum value of WEEK for each subject
   (suppress the printing of the output for this procedure) */
PROC MEANS NOPRINT; CLASS ID; VAR WEEK; OUTPUT OUT=TWO MAX=MAXWEEK;
RUN;

/* determine if a subject has data at WEEK 6
   DROPOUT  = 0 (for completers) or = 1 (for dropouts) */
DATA THREE; SET TWO;
     DROPOUT=0;
     IF MAXWEEK LT 6 THEN DROPOUT=1;

/* dataset with all subjects (adding the DROPOUT variable) */
DATA FOUR; MERGE ONE THREE; BY ID;

/* Random intercept model */
TITLE2 'Analysis on All subjects: random intercept model';
PROC MIXED DATA=FOUR METHOD=ML COVTEST;
  CLASS ID;
  MODEL IMPS79 = SWEEK DRUG SWEEK*DRUG / SOLUTION ;
  RANDOM INTERCEPT /SUB=ID TYPE=UN G;
RUN;

/* Random intercept and trend model */
TITLE2 'Analysis on All subjects: random intercept and trend model';
PROC MIXED DATA=FOUR METHOD=ML COVTEST;
  CLASS ID;
  MODEL IMPS79 = SWEEK DRUG SWEEK*DRUG / SOLUTION;
  RANDOM INTERCEPT SWEEK /SUB=ID TYPE=UN G GCORR;
RUN;

/* Pattern-mixture random intercept and trend model
   NOTE: the COVB option name on the MAKE statement reflects
   the change made by SAS beginning with release 6.12
   This option name was previously XPVIXI */
TITLE2 'Analysis on All subjects - Pattern-Mixture Model';
PROC MIXED DATA=FOUR METHOD=ML COVTEST;
  MAKE 'SOLUTIONF' OUT=ESTB;
  MAKE 'COVB'      OUT=VCOV;
  CLASS ID;
  MODEL IMPS79 = SWEEK DRUG SWEEK*DRUG
                 DROPOUT DROPOUT*SWEEK
                 DROPOUT*DRUG DROPOUT*DRUG*SWEEK / SOLUTION COVB;
  RANDOM INTERCEPT SWEEK /SUB=ID TYPE=UN G GCORR;
RUN;


/* use IML to get the results averaged over the missing data patterns */
PROC IML;

USE VCOV;
READ ALL INTO VCOVM;
PRINT 'Asymptotic Variance Covariance - Fixed effects',VCOVM[FORMAT=8.4];

USE ESTB;
READ ALL INTO ESTBM;
PRINT 'Proc MIXED estimates ', ESTBM [FORMAT=8.4];

MEANV = ESTBM[,1];      /* put estimates only in MEANV */
VARB  = VCOVM[1:8,2:9]; /* ignore last row (relates to y and not x)
                           and first column (parameter number)      */


/* Completers n=70+265=335 are the first four rows     */
/* Dropouts   n=38+64=102  add in the last four rows   */

A = { 1 0 0 0  0 0 0 0,   /* Completer - control intercept      */
      0 1 0 0  0 0 0 0,   /* Completer - control slope          */
      0 0 1 0  0 0 0 0,   /* Completer - drug    intercept diff */
      0 0 0 1  0 0 0 0,   /* Completer - drug    slope     diff */
      1 0 0 0  1 0 0 0,   /* Dropout   - control intercept      */
      0 1 0 0  0 1 0 0,   /* Dropout   - control slope          */
      0 0 1 0  0 0 1 0,   /* Dropout   - drug    intercept diff */
      0 0 0 1  0 0 0 1};  /* Dropout   - drug    slope     diff */

meancd = A*meanv;
varccd = A*varb*T(A);

print 'Completers (n=335)';
meanc = meancd[1:4,];
serrc = sqrt(vecdiag(varccd[1:4,1:4]));
zvalc = meanc/serrc;
probc = 2*(1-PROBNORM(abs(zvalc)));

print 'intercept & slope (placebo & drug diff)', meanc [FORMAT=8.4];
print 'standard errors                        ', serrc [FORMAT=8.4];
print 'z-statistics                           ', zvalc [FORMAT=8.4];
print 'p-values                               ', probc [FORMAT=8.4];


print 'Dropouts   (n=102)';
meand = meancd[5:8,];
serrd = sqrt(vecdiag(varccd[5:8,5:8]));
zvald = meand/serrd;
probd = 2*(1-PROBNORM(abs(zvald)));

print 'intercept & slope (placebo & drug diff)', meand [FORMAT=8.4];
print 'standard errors                        ', serrd [FORMAT=8.4];
print 'z-statistics                           ', zvald [FORMAT=8.4];
print 'p-values                               ', probd [FORMAT=8.4];



/* now apply the formulas given in Little (93) page 127
             to get the pattern-mixture averaged results
   and the delta method to get the standard errors
*/

/* missing-data pattern proportions given by marginal proportions */
propcd  = J(8,8,0);
propcd[1,1] = 335/437; /* Completer - placebo intercept      */
propcd[2,2] = 335/437; /* Completer - placebo slope          */
propcd[3,3] = 335/437; /* Completer - drug    intercept diff */
propcd[4,4] = 335/437; /* Completer - drug    slope     diff */
propcd[5,5] = 102/437; /* Dropout   - placebo intercept      */
propcd[6,6] = 102/437; /* Dropout   - placebo slope          */
propcd[7,7] = 102/437; /* Dropout   - drug    intercept diff */
propcd[8,8] = 102/437; /* Dropout   - drug    slope     diff */

/* variance of estimated proportions */
propcdd  = J(4,4,0);
propcdd[1,1] =  (335/437)*(102/437)/437;
propcdd[2,2] =  (335/437)*(102/437)/437;
propcdd[3,3] =  (335/437)*(102/437)/437;
propcdd[4,4] =  (335/437)*(102/437)/437;

/* indicator matrix to average over 2 patterns */
B = { 1 0 0 0  1 0 0 0,
      0 1 0 0  0 1 0 0,
      0 0 1 0  0 0 1 0,
      0 0 0 1  0 0 0 1};

/* derivative matrix for average with respect to proportion
   (for application of delta method)                        */
C = { 1 0 0 0  -1  0  0  0,
      0 1 0 0   0 -1  0  0,
      0 0 1 0   0  0 -1  0,
      0 0 0 1   0  0  0 -1};

meanpm =  B*propcd*meancd;
varcpm =  B*propcd*varccd*propcd*T(B)
          + propcdd*C*meancd*T(meancd)*T(C);
serrpm = sqrt(vecdiag(varcpm));
zvalpm = meanpm/serrpm;
probpm = 2*(1-PROBNORM(abs(zvalpm)));

print 'Pattern-mixture Averaged Results';
print 'Pattern-mixture proportions = marginal';
print 'intercept and slope (placebo & drug diff) ', meanpm [FORMAT=8.4];
print 'standard errors                           ', serrpm [FORMAT=8.4];
print 'z-statistics                              ', zvalpm [FORMAT=8.4];
print 'p-values                                  ', probpm [FORMAT=8.4];
