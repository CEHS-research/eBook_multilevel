FILENAME SDDat HTTP "https://hedeker.people.uic.edu/sdhouse.DAT.txt";
DATA  one; INFILE SDDat;
INPUT Id Housing Int Section8 Time1 Time2 Time3 Sect8T1 Sect8T2 Sect8T3
      NonSect8 LinTime S8LinT ;

      IF Housing = 999 then Housing = .;

/* Nominal random intercept logistic regression via GLIMMIX - independent random effects */
PROC GLIMMIX DATA=one METHOD=QUAD(QPOINTS=11) NOCLPRINT;
CLASS Id Housing;
MODEL Housing(REF=FIRST) = Time1 Time2 Time3 Section8 Sect8T1 Sect8T2 Sect8T3 / SOLUTION DIST=MULTINOMIAL LINK=GLOGIT;
RANDOM INTERCEPT / SUBJECT=Id GROUP=Housing;
RUN;

/* Nominal random intercept logistic regression via NLMIXED - correlated random effects */
PROC NLMIXED DATA=one QPOINTS=11;
PARMS b1_0=-.49 b1_Time1=1.63 b1_Time2=2.37 b1_Time3=1.8 b1_Section8=.43 b1_Sect8T1=-.46 b1_Sect8T2=-2.12 b1_Sect8T3=-1.1 var1=1
      b2_0=-1.7 b2_Time1=1.90 b2_Time2=2.97 b2_Time3=2.9 b2_Section8=.54 b2_Sect8T1=1.13 b2_Sect8T2=-.04  b2_Sect8T3=-.07 var2=1 covar=0;
z1 = b1_0 + b1_Time1*Time1 + b1_Time2*Time2 + b1_Time3*Time3 + b1_Section8*Section8
          + b1_Sect8T1*Sect8T1 + b1_Sect8T2*Sect8T2 + b1_Sect8T3*Sect8T3 + u1;
z2 = b2_0 + b2_Time1*Time1 + b2_Time2*Time2 + b2_Time3*Time3 + b2_Section8*Section8
          + b2_Sect8T1*Sect8T1 + b2_Sect8T2*Sect8T2 + b2_Sect8T3*Sect8T3 + u2;
IF (Housing=0) THEN
  p = 1 / (1 + EXP(z1) + EXP(z2));
ELSE IF (Housing=1) THEN
  p = EXP(z1) / (1 + EXP(z1) + EXP(z2));
ELSE IF (Housing=2) THEN
  p = EXP(z2) / (1 + EXP(z1) + EXP(z2));
LogLike = LOG(p);
MODEL Housing ~ GENERAL(LogLike);
RANDOM u1 u2 ~ NORMAL([0,0],[var1,covar,var2]) SUBJECT=Id;
ESTIMATE 'ICC1' var1 /((((ATAN(1)*4)**2)/3) + var1);
ESTIMATE 'ICC2' var2 /((((ATAN(1)*4)**2)/3) + var2);
ESTIMATE 're corr' covar/SQRT(var1*var2);
RUN;
