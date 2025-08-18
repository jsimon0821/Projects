<<<<<<< HEAD
IF OBJECT_ID('tempdb..#sick') IS NOT NULL
     DROP TABLE #sick

SELECT 
       a.a_employee_number AS emp_id
	  ,m.prem_lname AS last_name
	  ,m.prem_fname AS first_name
	  ,j.prjb_long AS job
	  ,CASE WHEN b.prbu_code < '1600' THEN 'Admin'
	        WHEN b.prbu_code < '2000' THEN 'Pro-Tech'
			WHEN b.prbu_code < '3000' THEN 'Instructional'
			WHEN b.prbu_code < '4000' THEN 'NNB'
			WHEN b.prbu_code < '5000' THEN 'SRP'
			ELSE 'Other'
       END AS bu_group
	  ,l.prln_long AS loc_desc
	  ,a.d_date_from AS absence_date
	  ,a.a_pay_short_name AS absence_type
	  ,a.d_unit_quantity AS used
	  ,'1' AS absence

INTO #sick

FROM pr_time_attendance a

LEFT JOIN prempmst m ON
a.a_employee_number = m.prem_emp AND
m.prem_proj = '0'

LEFT JOIN prlocatn l ON
a.prtd_loc = l.prln_code

LEFT JOIN prjobcls j ON
a.a_job_class = j.prjb_code AND
prjb_proj = '0'

LEFT JOIN prbargin b ON
j.prjb_barg_unit = b.prbu_code

WHERE d_absence = 'Y' AND
a_pay_type = '310' AND
d_date_from BETWEEN @sd AND @ed

SELECT 
     s.emp_id
	,s.last_name
	,s.first_name
	,s.bu_group
	,s.job
	,s.loc_desc
	,COUNT(s.absence) as sick_days
FROM #sick s

WHERE s.bu_group IN (@bu)

GROUP BY
     s.emp_id
	,s.last_name
	,s.first_name
	,s.job
    ,s.bu_group
	,s.loc_desc

=======
IF OBJECT_ID('tempdb..#sick') IS NOT NULL
     DROP TABLE #sick

SELECT 
       a.a_employee_number AS emp_id
	  ,m.prem_lname AS last_name
	  ,m.prem_fname AS first_name
	  ,j.prjb_long AS job
	  ,CASE WHEN b.prbu_code < '1600' THEN 'Admin'
	        WHEN b.prbu_code < '2000' THEN 'Pro-Tech'
			WHEN b.prbu_code < '3000' THEN 'Instructional'
			WHEN b.prbu_code < '4000' THEN 'NNB'
			WHEN b.prbu_code < '5000' THEN 'SRP'
			ELSE 'Other'
       END AS bu_group
	  ,l.prln_long AS loc_desc
	  ,a.d_date_from AS absence_date
	  ,a.a_pay_short_name AS absence_type
	  ,a.d_unit_quantity AS used
	  ,'1' AS absence

INTO #sick

FROM pr_time_attendance a

LEFT JOIN prempmst m ON
a.a_employee_number = m.prem_emp AND
m.prem_proj = '0'

LEFT JOIN prlocatn l ON
a.prtd_loc = l.prln_code

LEFT JOIN prjobcls j ON
a.a_job_class = j.prjb_code AND
prjb_proj = '0'

LEFT JOIN prbargin b ON
j.prjb_barg_unit = b.prbu_code

WHERE d_absence = 'Y' AND
a_pay_type = '310' AND
d_date_from BETWEEN @sd AND @ed

SELECT 
     s.emp_id
	,s.last_name
	,s.first_name
	,s.bu_group
	,s.job
	,s.loc_desc
	,COUNT(s.absence) as sick_days
FROM #sick s

WHERE s.bu_group IN (@bu)

GROUP BY
     s.emp_id
	,s.last_name
	,s.first_name
	,s.job
    ,s.bu_group
	,s.loc_desc

>>>>>>> c8cac85d15ad9610f65c5afedc64f7b9d6094a8a
ORDER BY loc_desc, last_name