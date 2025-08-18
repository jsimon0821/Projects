<<<<<<< HEAD
SELECT 
    j.prjb_code AS job_code
   ,j.prjb_long AS job_desc
   ,j.prjb_cat2 AS 'status'
   ,COUNT(p.prep_emp) AS employee_count
FROM prjobcls j

LEFT JOIN premppay p ON
j.prjb_code = p.prep_job AND
p.prep_base_pay = 'Y' AND
p.prep_inactive IN ('M','A','L') AND
p.prep_proj = '0'

WHERE j.prjb_proj = '0'

GROUP BY j.prjb_code, j.prjb_long, j.prjb_cat2



=======
SELECT 
    j.prjb_code AS job_code
   ,j.prjb_long AS job_desc
   ,j.prjb_cat2 AS 'status'
   ,COUNT(p.prep_emp) AS employee_count
FROM prjobcls j

LEFT JOIN premppay p ON
j.prjb_code = p.prep_job AND
p.prep_base_pay = 'Y' AND
p.prep_inactive IN ('M','A','L') AND
p.prep_proj = '0'

WHERE j.prjb_proj = '0'

GROUP BY j.prjb_code, j.prjb_long, j.prjb_cat2



>>>>>>> c8cac85d15ad9610f65c5afedc64f7b9d6094a8a
