/* Create dataset 'a' */
data a;
	set sashelp.class;
	output;
	sex='Male'; 
	output;
run;

/* Sort dataset 'a' */
proc sort data=a;
	by sex;
run;

/* Calculate statistics using PROC MEANS */
proc means data=a N Nmiss Mean Std Median q1 q3 min max noprint;
	output out=a1 N=n1 Nmiss=nmiss1 Mean=mean1 Std=std1 Median=median1 q1=q11 q3=q33 min=min1 max=max1;
	by sex;
	var height;
run;

/* Process the statistics dataset */
data a2(keep=NNMISS MEANSTD MEDIAN Q1Q3 MINMAX);
	set a1;
	N=compress(put(n1,best.));
	NNMISS=compress(put(n1,best.))||" ("||compress(put(nmiss1,best.))||")";
	MEANSTD=compress(put(mean1,8.2))||" ("||compress(put(std1,8.2))||')';
	MEDIAN=compress(put(MEDIAN1,8.2));
	Q1Q3=compress(put(q11,8.2))||","||compress(put(q33,8.2));
	MINMAX=compress(put(min1,8.2))||","||compress(put(max1,8.2));
run;

/* Transpose the dataset */
proc transpose data=a2 out=a3(rename=(COL1=col1 COL2=col2 COL3=col9));
	var NNmiss MeanStd median q1q3 minmax;
run;

/* Final processing of transposed dataset */
data a4;
	length label para col1 col2 col9 $200;
  	set a3;
  	if _n_=1 then label='Height';
	if _NAME_='NNMISS' then para='N(Nmiss)';
  	if _NAME_='MEANSTD' then para='Mean(SD)';
  	if _NAME_='MEDIAN' then para='Median';
  	if _NAME_='Q1Q3' then para='Q1,Q3';
  	if _NAME_='MINMAX' then para='Min~Max';
	drop _NAME_;
run;

/* Insert a blank row into dataset a4 */
proc sql;
    insert into a4
    set para=' ';
quit;

/* Perform ANOVA */
proc anova data=sashelp.class;
	class sex;
	model height=sex;
	ods output ModelANOVA=P1;
run;

/* Process ANOVA output */
data p1(keep=ProbF rename=(ProbF=P));
	set p1;
run;

data p1(keep=p2);
	length p2 $200;
	set p1;
	p1=p;
	p2='P='||compress(put(P1,7.4));
run;

data p1(rename=(p2=p));
	set p1;
run;

/* Merge datasets a4 and p1 */
data tmp;
	merge a4 p1;
run;

/* Create dataset 'rst' */
data rst;
	set sashelp.class(where=(11<=age<=15));
	output;
	sex='Male';
	output;
run;


data rst1;
	set rst;
	output;
	age=99;
	output;
run;


proc sort data=rst1;
	by sex;
run;

proc freq data=rst1 noprint;
	tables age/out=rst2;
	by sex;
run;


proc sort data=rst2;
	by age;
run;


proc transpose data=rst2 out=rst3 prefix=c;
	var count;
	by age;
run;


data rst4;
	length para $200;
	set rst3(drop=_label_ _name_);
	para=strip(put(age,best.));
	if age=99 then para='Total';
	drop age;
run;

/* Calculate counts for age groups */
proc sql noprint;
	select count(*) into: n1 from sashelp.class where sex='Male' and 11<=age<=15;
	select count(*) into: n2 from sashelp.class where sex='Female' and 11<=age<=15;
	select count(*) into: n9 from sashelp.class where 11<=age<=15;
quit;

/* Final processing of age group percentages */
data rst5;
	length label para col1 col2 col9 $200;
	set rst4;
	if _n_=1 then label='Age Group';
	if c1^=. then col1=compress(put(c1,best.))||' ('||compress(put(c1/&n1.*100,8.1))||'%)';
	if c2^=. then col2=compress(put(c2,best.))||' ('||compress(put(c2/&n2.*100,8.1))||'%)';
	if c3^=. then col9=compress(put(c3,best.))||' ('||compress(put(c3/&n9.*100,8.1))||'%)';
	drop c1 c2 c3;
run;

/* Perform non-parametric test */
proc npar1way data=sashelp.class wilcoxon noprint;
	class sex;
	var age;
  	output out=p2;
run;

data p2(keep=P_KW rename=(P_KW=P));
	set p2;
run;

data p2(keep=p2);
	length p2 $200;
	set p2;
  	p1=p;
  	p2='P='||compress(put(P1,8.4));
run;

data p2(rename=(p2=P));
	set p2;
run;

/* Merge datasets rst5 and p2 */
data rst6;
	merge rst5 p2;
run;

/* Merge datasets tmp and rst6 */
data test.test1;
	set tmp rst6;
run;
