--This report ranks all employees' salaries within the school district for the current year after January 1st; some employees have 
--more than one job, so this report also sums the salaries for each employee.


WITH sal AS (

SELECT DISTINCT
    p.prep_emp AS emp_id
   ,LTRIM(CONCAT(m.a_name_first,' ',m.a_name_last)) AS full_name
   ,CONCAT(p.prep_job,' - ',m.a_job_class_desc) AS job
   ,CONCAT(p.prep_loc,' - ',m.a_location_p_desc) AS loc
   ,CASE WHEN RANK() OVER (PARTITION BY p.prep_emp ORDER BY p.prep_job) = 1
         THEN SUM(p.prep_ann_sal) OVER(PARTITION BY p.prep_emp) 
		 ELSE NULL
	END AS annual_salary
FROM premppay p

LEFT JOIN pr_employee_master m ON
p.prep_emp = m.a_employee_number AND
m.a_projection = '0' AND
m.e_terminated_date IS NULL

WHERE p.prep_proj = '0' AND
p.prep_base_pay = 'Y' AND
p.prep_bgnu < '7000' AND
p.prep_inactive != 'I' AND
m.e_activity_status != 'I' AND
p.prep_step_date > DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) AND
p.prep_pay IN ('100' , '101' , '105' , '110' ) )

SELECT *

FROM sal

WHERE annual_salary IS NOT NULL

