--This query pulls employee certifications that are expiring within the next month.

SELECT 
     c.prce_emp
	,CONCAT(m.a_name_first,' ',m.a_name_last) AS full_name
	,certif.prms_long AS cert_name
	,c.prce_area AS area_code
	,a.prms_long AS area_desc
	,c.prce_number
	,CAST(c.prce_eff_date AS DATE) AS effective_date
	,CAST(c.prce_exp_date AS DATE) AS expiration_date
FROM prempcer c

LEFT JOIN prmisccd certif ON
certif.prms_code = c.prce_type AND
certif.prms_type = 'CERT'

LEFT JOIN prmisccd a ON
a.prms_code = c.prce_area AND
a.prms_type = 'AREA'

INNER JOIN pr_employee_master m ON
c.prce_emp = m.a_employee_number AND
m.a_projection = '0'

WHERE c.prce_exp_date >= GETDATE() AND
      c.prce_exp_date < DATEADD(MONTH, 1, GETDATE())