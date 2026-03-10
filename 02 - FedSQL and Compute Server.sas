****************************************************************;
* SAS COMPUTE SERVER - DATABASE PROCESSING                     *;
****************************************************************;

*******************************************************************;
* 1. Connect to Oracle using the traditional SAS/ACCESS Interface *;
*******************************************************************;
libname or_db oracle path="//server.demo.sas.com:1521/ORCL"
                     authDomain="OracleAuth"
                     schema="STUDENT";

****************************************************************;
* 2. IMPLICIT PASS THROUGH WITH FEDSQL ON SAS COMPUTE SERVER   *;
****************************************************************;
* SAS will attempt to convert PROC FedSQL into native database *;
* SQL wherever possible. If it can't convert the SQL it will   *;
* bring the data to the SAS Compute Server for processing.     *;
****************************************************************;
* NOTE: Implicit pass-through features vary by database.       *;
****************************************************************; 

****************************************************************;
* a. By default, no pass through information goes into the log *;
*    The options that put additional information into the log  *;
*    for PROC SQL do not affect PROC FedSQL.                   *;
****************************************************************;
options sasTrace=',,,d' sasTraceLoc=sasLog noStSuffix;

proc fedsql;
select distinct LoanGrade
   from or_db.loans_raw
   order by LoanGrade
;
quit;
            
*****************************************************************; 
* b. The _method option on the PROC FedSQL statement places     *;
*    text in the log for that step. This query runs in the      *;
*    database.                                                  *;
*****************************************************************; 
proc fedsql _method;
select distinct LoanGrade
   from or_db.loans_raw
   order by LoanGrade
;
quit;

*****************************************************************; 
* c. This query runs partly in SAS.                             *;
*****************************************************************; 

proc fedsql _method;
select distinct LoanGrade
   from or_db.loans_raw
   where scan(cancelledReason, 1) = 'Bad'
   order by LoanGrade
;
quit;

*******************************************************************************************;
* _method is an undocumented option, so no documentation link is available for this topic *;
*******************************************************************************************;  


******************************************************************;
* 3. EXPLICIT PASS-THROUGH WITH FEDSQL ON THE SAS COMPUTE SERVER *;
******************************************************************;
* Use native Oracle SQL through PROC FedSQL                      *;
******************************************************************;  
proc fedsql;
create table work.example as
select *
    from connection to or_db 
    (select EXTRACT( YEAR FROM "LastPurchase") as 
                                                LastPurchaseYear,
             count(*) as Total,
             count(*)/(select count(*) 
                         from loans_raw 
                         where "Category" = 'Credit Card') as LastPurchasePct
        from loans_raw
        where "Category" = 'Credit Card'
        group by EXTRACT(YEAR FROM "LastPurchase")
        order by Total desc
    )
;
quit;

***********************************************************************************************************;
* Explicit Pass Through with FedSQL Documentation:                                                        *;
*   https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/fedsqlref/p1t7brk6e1lguwn1j4icn4s058h6.htm  *;
***********************************************************************************************************;