--This CTE pulls all active school employees who work at a Title 1 grant-funded school, as well as their information.

WITH t1 AS (

SELECT DISTINCT
    a_employee_number AS emp_id
   ,CONCAT(m.a_name_first,' ',m.a_name_last) AS full_name
   ,CASE WHEN b.prbu_code < '1600' THEN 'Admin'
         WHEN b.prbu_code < '2000' THEN 'Pro-Tech'
		 WHEN b.prbu_code < '3000' THEN 'Instructional'
		 WHEN b.prbu_code < '4000' THEN 'NNB'
		 WHEN b.prbu_code < '5000' THEN 'SRP'
		 WHEN b.prbu_code = '6000' THEN 'Students'
		 WHEN b.prbu_code = '6200' THEN 'Substitutes'
		 WHEN b.prbu_code = '6400' THEN 'Temps'
		 ELSE ''
	END AS bu_group
   ,m.a_job_class_desc AS job
   ,m.a_location_p_desc AS loc
   ,m.e_email AS email

FROM pr_employee_master m

LEFT JOIN prbargin b ON
m.a_bargain_primary = b.prbu_code

INNER JOIN rq_bill_ship l ON
l.rs_bill_ship_code = m.a_location_primary AND
SUBSTRING(l.rs_fax, 7 , 1) = 'T'

WHERE m.a_projection = '0' AND
m.e_activity_status = 'A' AND
m.e_terminated_date IS NULL AND
m.a_bargain_primary < '7000'


)

--This SELECT statement gets a count of the Title 1 school employees, both by location and by type of employee, i.e. Administrator and Instructional.

SELECT
   loc
  ,bu_group
  ,COUNT(emp_id) AS t1_emp_count
FROM t1

GROUP BY bu_group, loc


