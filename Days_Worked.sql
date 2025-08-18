
-- This report lists employees tenure at schools and categorizes them by how many days each school year to determine the need for an evaluation at their work location




-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a table to list calendar work days.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#work') IS NOT NULL  
	DROP TABLE #work

SELECT
	 c.prcd_code AS cal_code
	,c.prcd_date AS work_day
	
INTO
	#work
FROM
	prcaldet c

WHERE	1=1
AND	c.prcd_type != 'N'
AND	c.prcd_date BETWEEN @s AND @e

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a table to list employee job information.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#jp1') IS NOT NULL  
	DROP TABLE #jp1

SELECT
	 p.prep_emp AS emp_id
	,m.prem_lname AS last_name
	,m.prem_fname AS first_name
	,p.prep_job	AS job_code
	,j.prjb_long AS job_desc
	,p.prep_pay	AS pay_type
	,p.prep_calndr	AS cal_code
	,CASE WHEN p.prep_loc = '0991' THEN '8991'
	      WHEN p.prep_loc IN ('7004','7006','7023') THEN '7004'
	      ELSE p.prep_loc
	 END AS loc_code
	,l.prln_long AS loc_desc
	,CASE WHEN p.prep_bgnu < '2000' THEN 'Admin'
          WHEN p.prep_bgnu < '3000' THEN 'Instructional'
		  WHEN p.prep_bgnu < '4000' THEN 'NNB'
		  WHEN p.prep_bgnu < '5000' THEN 'SRP'
		  WHEN p.prep_bgnu = '7300' THEN 'Summer Instructional'
          WHEN p.prep_bgnu = '7310' THEN 'Summer Non-Instructional'
		  WHEN p.prep_bgnu = '9000' THEN 'Charter Intructional'
		  WHEN p.prep_bgnu = '9001' THEN 'Charter Schools Inst Support'
		  WHEN p.prep_bgnu = '9002' THEN 'Charter Admin'
          WHEN p.prep_bgnu = '9003' THEN 'Charter Schools Non-Inst'
          WHEN p.prep_bgnu = '9007' THEN 'Charter Contract Non-Inst'
		  WHEN p.prep_bgnu = '9008' THEN 'Charter Contract Admin'
          WHEN p.prep_bgnu = '9009' THEN 'Charter Contract Inst Support'
		  WHEN p.prep_bgnu = '9010' THEN 'Charter Contract Teacher'
		  ELSE p.prep_bgnu
	 END AS bu_group
	,p.prep_fte_pct AS FTE
	,p.prep_start	AS start_date
	,p.prep_end 	AS end_date
	,p.prep_days_per_yr AS days_per_year
	,p.prep_step_date AS transfer_date

INTO
	#jp1
FROM
	premppay_all p

LEFT JOIN prempmst m ON
p.prep_emp = m.prem_emp AND 
m.prem_proj = '0'

LEFT JOIN prjobcls j ON
p.prep_job = j.prjb_code AND
j.prjb_proj = '0'

LEFT JOIN prlocatn l ON
p.prep_loc = l.prln_code

LEFT JOIN pmachist h ON
p.prep_emp = h.pmah_emp AND
p.prep_pos = h.pmah_position AND
p.prep_job = h.pmah_job AND
p.prep_start = h.pmah_start AND
p.prep_end = h.pmah_end AND
p.prep_org = h.pmah_org AND
p.prep_obj = h.pmah_obj AND
p.prep_d_proj = h.pmah_d_proj AND
h.pmah_proj = '0' AND
h.pmah_act_code IN ('S005','S100','L100')

WHERE	1=1 AND	
p.prep_proj = 0 AND	
p.prep_pay IN ( '100' , '105' , '110' ) AND	
p.prep_bgnu < '3000' AND
p.prep_job NOT IN ('3049','3053','3058','3061','3086','3918') 

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Combine work days and job information.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#jp') IS NOT NULL  
	DROP TABLE #jp

SELECT
	 #jp1.emp_id
	,#jp1.last_name
	,#jp1.first_name
	,#jp1.job_code
	,#jp1.job_desc
	,#jp1.pay_type
	,#jp1.cal_code
	,#jp1.loc_code
	,#jp1.loc_desc
	,#jp1.FTE
	,#jp1.bu_group
	,#jp1.start_date
	,#jp1.end_date
	,#jp1.transfer_date
	,#jp1.days_per_year
	,#work.work_day AS days_worked

INTO
	#jp
FROM
	#jp1

LEFT JOIN
	#work
ON
	#work.cal_code = #jp1.cal_code
AND	#work.work_day BETWEEN #jp1.start_date AND #jp1.end_date

WHERE	1=1
AND	#work.cal_code IS NOT NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Generate employees' worked days.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#jpy') IS NOT NULL  
	DROP TABLE #jpy

SELECT 
	 #jp.emp_id
	,#jp.last_name
	,#jp.first_name
	,#jp.loc_code
	,#jp.loc_desc
	,#jp.job_desc
	,#jp.bu_group
	,#jp.FTE
	,#jp.start_date
	,#jp.end_date
	,CASE WHEN ROW_NUMBER() OVER (PARTITION BY #jp.emp_id ORDER BY #jp.start_date, #jp.end_date) = 1 THEN NULL ELSE #jp.transfer_date END AS transfer_date
	,COUNT ( DISTINCT #jp.days_worked ) AS job_days
	,#jp.days_per_year

INTO 
	#jpy
FROM
	#jp

GROUP BY
	 #jp.emp_id
	,#jp.last_name
	,#jp.first_name
	,#jp.loc_code
	,#jp.loc_desc
	,#jp.FTE
	,#jp.job_desc
	,#jp.bu_group
	,#jp.start_date
	,#jp.end_date
	,#jp.transfer_date
	,#jp.days_per_year

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Find employees who worked more than one location.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#multi') IS NOT NULL
      DROP TABLE #multi

SELECT
    emp_id
   ,last_name
   ,first_name
   ,COUNT(DISTINCT loc_code) AS loc_count

INTO #multi

FROM #jpy

GROUP BY emp_id, last_name, first_name

HAVING COUNT(DISTINCT loc_code) > 1;

SELECT DISTINCT
    #jpy.emp_id
   ,#jpy.last_name
   ,#jpy.first_name
   ,#jpy.loc_code
   ,#jpy.loc_desc
   ,#jpy.job_desc
   ,#jpy.bu_group
   ,#jpy.FTE
   ,#jpy.start_date
   ,#jpy.end_date
   ,#jpy.transfer_date
   ,#jpy.job_days
   ,CASE WHEN #jpy.bu_group = 'Instructional' AND #jpy.job_days > 99 AND #jpy.loc_code < '9000' THEN 'Yes'
         ELSE ' '
	END AS over_99
   ,CASE WHEN #jpy.bu_group = 'Admin' AND #jpy.days_per_year = 216 AND #jpy.job_days > 109 AND #jpy.loc_code < '9000' THEN 'Yes'
		 ELSE ' '
	END AS over_109
   ,CASE WHEN #jpy.bu_group = 'Admin' AND #jpy.days_per_year = 230 AND #jpy.job_days > 116 AND #jpy.loc_code < '9000' THEN 'Yes' 
         ELSE ' '
	END AS over_116
   ,CASE WHEN #jpy.bu_group = 'Admin' AND #jpy.days_per_year = 245 AND #jpy.job_days > 123 AND #jpy.loc_code < '9000' THEN 'Yes' 
         ELSE ' '
	END AS over_123
FROM #jpy 

INNER JOIN #multi ON
#jpy.emp_id = #multi.emp_id

WHERE (#jpy.start_date BETWEEN @s AND @e OR
       #jpy.end_date BETWEEN @s AND @e) AND
	   #jpy.start_date != #jpy.end_date

ORDER BY #jpy.emp_id, #jpy.start_date, #jpy.end_date
