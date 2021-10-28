OPTIONS NOCENTER LINESIZE=81 PAGESIZE=66 ;
TITLE1 'Analysis of TVSFP data - Regression of Post-test THKS scores';

DATA tvsfp;
INFILE 'C:\mixdemo\tvsfp.dat';
INPUT SCHOOLID CLASSID POSTHKS INT PRETHKS CC TV CCTV;

PROC FORMAT;
     VALUE  CC  0='NO' 1='YES' ;
     VALUE  TV  0='NO' 1='YES' ;

/* student-level OLS analysis ignoring clustering */
PROC REG;
     MODEL POSTHKS = PRETHKS CC TV CCTV;
     TITLE2 'OLS Student-level analysis ignoring clustering';

/* student-level ML analysis ignoring clustering */
PROC MIXED method=ml covtest;
     MODEL POSTHKS = PRETHKS CC TV CCTV / SOLUTION;
     TITLE2 'ML Student-level anaylsis ignoring clustering';

/* 2-level: students nested within classrooms analysis */
PROC MIXED method=ml covtest;
     CLASS CLASSID;
     MODEL POSTHKS = PRETHKS CC TV CCTV / SOLUTION;
     RANDOM INTERCEPT / SUB=CLASSID;
     TITLE2 '2-level: students nested within classrooms analysis';

/* 2-level: students nested within schools analysis */
PROC MIXED method=ml covtest;
     CLASS SCHOOLID;
     MODEL POSTHKS = PRETHKS CC TV CCTV / SOLUTION;
     RANDOM INTERCEPT / SUB=SCHOOLID;
     TITLE2 '2-level: students nested within schools analysis';

/* 3-level: students nested within classrooms nested within schools analysis */
PROC MIXED method=ml covtest;
     CLASS CLASSID SCHOOLID;
     MODEL POSTHKS = PRETHKS CC TV CCTV / SOLUTION;
     RANDOM INTERCEPT / SUB=SCHOOLID;
     RANDOM INTERCEPT / SUB=CLASSID(SCHOOLID);
     TITLE2 '3-level: students within classrooms within schools analysis';
RUN;


/* get class-level means for aggregate analysis */
PROC MEANS NOPRINT;
     CLASS CLASSID;
     VAR POSTHKS PRETHKS CC TV CCTV;
     OUTPUT OUT = TVSFPC
     MEAN(POSTHKS PRETHKS CC TV CCTV) = POSTHKSC PRETHKSC CCC TVC CCTVC;
RUN;

PROC PRINT DATA=TVSFPC;
     TITLE2 'Listing of aggregated dataset';

/* get rid of the observation that is the grand mean (across all subjects) */
DATA TVSFPC2; SET TVSFPC; IF _TYPE_ NE 0;

/* aggregate classroom analysis */
PROC REG DATA=TVSFPC2;
     MODEL POSTHKSC = PRETHKSC CCC TVC CCTVC;
     TITLE2 'Classroom-level aggregate analysis';
RUN;
