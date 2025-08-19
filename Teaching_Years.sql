--This report pulls all the teaching jobs and gives a count of employees in each one as well as average, minimum and maximum years of teaching in each one.

WITH emp AS (
SELECT 
    y.prsv_emp
   ,y.prsv_total_yrs
   ,m.a_job_code_primary
   ,m.a_job_class_desc
FROM prsvyrdt y

INNER JOIN pr_employee_master m ON
y.prsv_emp = m.a_employee_number AND
m.a_projection = '0'

WHERE y.prsv_proj = '0' AND
prsv_last_upd_yr = YEAR(GETDATE()) AND
y.prsv_summ_cat = '5030'),

job AS (
SELECT 
   j.prjb_code
  ,j.prjb_long
FROM prjobcls j

WHERE j.prjb_proj = '0' AND
j.prjb_barg_unit BETWEEN '2000' AND '2999')

SELECT 
     job.prjb_long AS job
	,COUNT(emp.prsv_emp) AS employee_count
	,CAST(ROUND(AVG(emp.prsv_total_yrs), 2) AS DECIMAL(9,2)) AS avg_teaching_years
	,MIN(emp.prsv_total_yrs) AS min_teaching_years
	,MAX(emp.prsv_total_yrs) AS max_teaching_years

FROM emp

INNER JOIN job ON
emp.a_job_code_primary = job.prjb_code

GROUP BY job.prjb_long

ORDER BY job.prjb_long
