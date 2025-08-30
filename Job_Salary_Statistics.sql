--This query takes all the jobs in the school district, counts how many employees are in each job, and calculates the annual salary summary statistics of each job.

WITH job AS (
SELECT 
    p.prep_job AS job_code
   ,job.prjb_long AS job_desc
   ,p.prep_ann_sal AS annual_salary
FROM premppay p

LEFT JOIN prjobcls job ON
p.prep_job = job.prjb_code AND
job.prjb_proj = '0'

WHERE p.prep_proj = '0' AND
p.prep_inactive = 'A' AND
p.prep_base_pay = 'Y' AND 
p.prep_primary = 'Y' AND
p.prep_pay != '190' AND
p.prep_ann_sal != '0'),

calc AS (

SELECT
    j.job_desc
   ,COUNT(*) AS emp_count
   ,ROUND(AVG(CAST(j.annual_salary AS FLOAT)), 2) AS average_salary
   ,MIN(j.annual_salary) AS min_salary
   ,MAX(j.annual_salary) AS max_salary
   ,ROUND(STDEV(CAST((j.annual_salary) AS FLOAT)), 2) AS sd_salary
FROM job j

GROUP BY j.job_desc)

SELECT 
    c.job_desc
   ,c.emp_count
   ,c.min_salary
   ,c.max_salary
   ,c.average_salary
   ,c.sd_salary
   ,c.max_salary - c.min_salary AS salary_range
   ,CONCAT(c.average_salary - c.sd_salary,' - ',c.average_salary + c.sd_salary) AS sixty_six_sd
   ,CONCAT(c.average_salary - (c.sd_salary * 2),' - ',c.average_salary + (c.sd_salary * 2)) as ninety_five_sd
   ,CONCAT(c.average_salary - (c.sd_salary * 3),' - ',c.average_salary + (c.sd_salary * 3)) as ninety_nine_sd
   ,CASE WHEN c.min_salary < (c.average_salary - c.sd_salary * 3) THEN 'Yes'
         ELSE ''
    END AS lower_outliers
   ,CASE WHEN c.max_salary > (c.average_salary + c.sd_salary * 3) THEN 'Yes'
         ELSE ''
    END AS upper_outliers
FROM calc c

ORDER BY c.job_desc

