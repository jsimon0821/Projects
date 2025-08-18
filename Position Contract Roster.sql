<<<<<<< HEAD
-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create an Allocation Table
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#a') IS NOT NULL   
     DROP TABLE #a 

 SELECT 
     pra.a_allocation_code AS alloc_code 
    ,gl.fund 

INTO #a 

FROM pr_allocations pra

LEFT JOIN 
      (SELECT 
           a_object 
          ,a_project 
          ,a_org 
          ,b_full_account AS fund  
       FROM gl_long_account 
       WHERE 1=1 
) AS gl 

 

ON gl.a_object = pra.an_object AND 
gl.a_project = pra.an_project AND 
gl.a_org = pra.an_org 

 
WHERE 1=1 AND 
pra.a_projection = 0 


-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create an Allocation Stuffed Table 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#s') IS NOT NULL   
      DROP TABLE #s 

 SELECT DISTINCT 
           #a.alloc_code 
           ,STUFF (  
           (SELECT DISTINCT 
            ' | ' + s2.fund 
            FROM #a AS s2 
            WHERE 1=1 AND 
			#a.alloc_code = s2.alloc_code 
            FOR XML PATH ('') 
			) , 1,2,'' ) AS fund 

INTO #s 

FROM #a 

ORDER BY alloc_code 

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Certification Table.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#cert') IS NOT NULL
      DROP TABLE #cert

CREATE TABLE #cert (
             employee_number VARCHAR (10)
			,last_name VARCHAR (50)
			,first_name VARCHAR (50)
			,job_code VARCHAR (10)
			,job_desc VARCHAR (50)
			,loc_code VARCHAR (10)
			,loc_desc VARCHAR (50)
			,certification VARCHAR (MAX)
			,cert_area VARCHAR (MAX)
)

INSERT INTO #cert (
             employee_number
			,last_name
			,first_name
			,job_code
			,job_desc
			,loc_code
			,loc_desc
			,certification
			,cert_area
)

SELECT DISTINCT
     c.prce_emp
	,m.prem_lname
	,m.prem_fname
	,m.prem_p_jclass
	,j.prjb_long
	,m.prem_loc
	,l.prln_long
	,certif.prms_long
	,STRING_AGG(RTRIM(area.prms_long),', ')
FROM prempcer c

LEFT JOIN prempmst m ON
c.prce_emp = m.prem_emp AND
m.prem_proj = '0'

LEFT JOIN prjobcls j ON
j.prjb_code = m.prem_p_jclass AND
j.prjb_proj = '0'

LEFT JOIN prlocatn l ON
m.prem_loc = l.prln_code

LEFT JOIN prmisccd certif ON
c.prce_type = certif.prms_code AND
certif.prms_type = 'CERT'

LEFT JOIN prmisccd area ON
c.prce_area = area.prms_code AND
area.prms_type = 'AREA'

WHERE c.prce_proj = '0' AND
c.prce_type IN ('PRF','TMP','ILC','MCRD') AND
m.prem_act_stat NOT IN ('I','M')

GROUP BY  c.prce_emp, m.prem_lname, m.prem_fname, m.prem_p_jclass, j.prjb_long, m.prem_loc, l.prln_long, certif.prms_long

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Contract Table.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#contr') IS NOT NULL
       DROP TABLE #contr

CREATE TABLE #contr (
                emp_num VARCHAR (10)
			   ,last_name VARCHAR (50)
			   ,first_name VARCHAR (50)
			   ,job_code VARCHAR (10)
			   ,bargain VARCHAR (10)
			   ,bargain_desc VARCHAR (50)
			   ,contract_code VARCHAR (20)
			   ,contract_type VARCHAR (60)
)

INSERT INTO #contr (
               emp_num
			  ,last_name
			  ,first_name
			  ,job_code
			  ,bargain
			  ,bargain_desc
			  ,contract_code
			  ,contract_type
)

SELECT DISTINCT
      m.prem_emp
	 ,CONCAT(LEFT(m.prem_lname, 1) ,RTRIM(LOWER(SUBSTRING(m.prem_lname, 2, 100))))
	 ,CONCAT(LEFT(m.prem_fname, 1) ,RTRIM(LOWER(SUBSTRING(m.prem_fname, 2, 100))))
	 ,m.prem_p_jclass
	 ,m.prem_p_bargain
	 ,b.prbu_long
	 ,CASE WHEN p_contract.c_desc = 'PROFESSIONAL SERVICE CONTRACT' THEN p_contract.c_code
	       ELSE	contract.c_code
	  END AS contract_code
	 ,CASE WHEN	p_contract.c_desc = 'PROFESSIONAL SERVICE CONTRACT' THEN p_contract.c_desc
		   ELSE	contract.c_desc
	  END AS contract_type

FROM prempmst m

LEFT JOIN (SELECT
			 u.prus_emp AS emp_id
			,u.prus_code AS c_code
			,d.LongDescription AS c_desc
		    
		   FROM prempusr u

	       LEFT JOIN HRUserDefinedCodes AS d
		   ON d.Code = u.prus_code

	       WHERE 1=1 AND	
		   u.prus_proj = '0' AND	
		   u.prus_usr_cd = '1200') AS p_contract 
		   ON p_contract.emp_id = m.prem_emp

LEFT JOIN (SELECT
			 u.prus_emp AS emp_id
			,u.prus_code AS c_code
			,d.LongDescription	AS c_desc
		
		   FROM prempusr u

		   LEFT JOIN HRUserDefinedCodes AS d 
		   ON d.Code = u.prus_code

		   WHERE 1=1 AND	
		   u.prus_proj = '0' AND	
		   u.prus_usr_cd = '1220') AS contract 
		   ON contract.emp_id = m.prem_emp
           

LEFT JOIN prlocatn l
ON m.prem_loc = l.prln_code

LEFT JOIN prbargin b 
ON m.prem_p_bargain = b.prbu_code

LEFT JOIN premppay p 
ON m.prem_p_jclass = p.prep_job AND
p.prep_proj = '0'

WHERE prem_proj = '0' AND
m.prem_act_stat NOT IN ('I','M') AND
m.prem_p_bargain BETWEEN '1200' AND '3999' AND
m.prem_p_jclass NOT IN ( '3049' , '3053' , '3058' , '3061' , '3918' ) AND
contract.c_code IS NOT NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- SELECTION
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------



SELECT 
    p.pmpc_position AS pos 
   ,p.pmpc_desc AS pos_desc 
   ,p.pmpc_job_class AS job_code 
   ,RTRIM ( pr_job_class.a_job_class_desc ) AS job_desc 
   ,p.pmpc_bgnu AS bu 
   ,p.pmpc_loc AS loc_code 
   ,IIF ( p.pmpc_freeze = 'Y' , p.pmpc_max_employees , 0 ) AS frozen_units 
   ,IIF ( p.pmpc_freeze = 'N' , p.pmpc_max_employees , 0 ) AS budget_units 
   ,p.pmpc_cy_fte_act AS occupied_units 
   ,p.pmpc_max_employees - p.pmpc_cy_fte_act AS remain_units 
   ,jp.name 
   ,jp.emp_id 
   ,jp.fte
   ,jp.days_year
   ,jp.hours_day 
   ,jp.inst_senior
   ,jp.service_date
   ,#contr.contract_type
   ,#contr.contract_code
   ,jp.emp_status 
   ,jp.pay_status 
   ,#cert.certification
   ,#cert.cert_area
   ,CASE WHEN #s.alloc_code IS NULL THEN gl.fund 
         ELSE #s.fund 
    END AS fund 

FROM pmposctl p

LEFT JOIN 
      (SELECT 
          a_object 
         ,a_project 
         ,a_org 
         ,b_full_account AS fund 
       FROM gl_long_account 

WHERE 1=1 

) AS gl 

 

ON gl.a_object = p.pmpc_obj AND 
gl.a_project = p.pmpc_proja AND 
gl.a_org = p.pmpc_org 

 
LEFT JOIN #s 

ON #s.alloc_code = p.pmpc_cy_alloc 

LEFT JOIN pr_job_class 

ON pr_job_class.a_job_class_code = p.pmpc_job_class AND 
pr_job_class.a_projection = p.pmpc_proj 

 LEFT JOIN 
      (SELECT 
           p.prep_emp AS emp_id 
          ,master.name AS 'name'
          ,p.prep_fte_pct AS fte 
		  ,p.prep_days_per_yr AS days_year
          ,p.prep_dayhrs AS hours_day 
          ,p.prep_start AS date_start 
          ,p.prep_end AS date_end 
          ,p.prep_job AS job_code 
          ,p.prep_pos AS pos_code 
          ,p.prep_inactive AS pay_status 
          ,master.emp_status
          ,master.inst_senior
          ,master.service_date

FROM premppay p 

LEFT JOIN 
      (SELECT 
           m.prem_emp AS emp_id 
          ,CONCAT ( RTRIM ( m.prem_lname ) , ', ' , RTRIM ( m.prem_fname ) , ' ' , RTRIM ( m.prem_minit ) ) AS name 
          ,m.prem_act_stat AS emp_status 
          ,m.prem_perm AS inst_senior
          ,m.prem_service AS service_date

	   FROM prempmst m
       WHERE 1=1 AND 
	   m.prem_proj = 0 AND
	   m.prem_act_stat IN ('A','B') 
      ) AS master 

ON master.emp_id = p.prep_emp 

 WHERE 1=1 AND 
 master.name IS NOT NULL AND 
 p.prep_proj = 0 AND 
 p.prep_base_pay = 'Y'  AND 
 p.prep_inactive != 'I' AND
 p.prep_loc IN (@loc)
) AS jp 

ON jp.pos_code = p.pmpc_position 

LEFT JOIN #contr
ON jp.emp_id = #contr.emp_num

LEFT JOIN #cert
ON jp.emp_id = #cert.employee_number

WHERE 1=1 AND 
p.pmpc_proj = 0 AND
p.pmpc_loc IN (@loc) AND
p.pmpc_status IN (@pstat) AND
=======
-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create an Allocation Table
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#a') IS NOT NULL   
     DROP TABLE #a 

 SELECT 
     pra.a_allocation_code AS alloc_code 
    ,gl.fund 

INTO #a 

FROM pr_allocations pra

LEFT JOIN 
      (SELECT 
           a_object 
          ,a_project 
          ,a_org 
          ,b_full_account AS fund  
       FROM gl_long_account 
       WHERE 1=1 
) AS gl 

 

ON gl.a_object = pra.an_object AND 
gl.a_project = pra.an_project AND 
gl.a_org = pra.an_org 

 
WHERE 1=1 AND 
pra.a_projection = 0 


-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create an Allocation Stuffed Table 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#s') IS NOT NULL   
      DROP TABLE #s 

 SELECT DISTINCT 
           #a.alloc_code 
           ,STUFF (  
           (SELECT DISTINCT 
            ' | ' + s2.fund 
            FROM #a AS s2 
            WHERE 1=1 AND 
			#a.alloc_code = s2.alloc_code 
            FOR XML PATH ('') 
			) , 1,2,'' ) AS fund 

INTO #s 

FROM #a 

ORDER BY alloc_code 

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Certification Table.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#cert') IS NOT NULL
      DROP TABLE #cert

CREATE TABLE #cert (
             employee_number VARCHAR (10)
			,last_name VARCHAR (50)
			,first_name VARCHAR (50)
			,job_code VARCHAR (10)
			,job_desc VARCHAR (50)
			,loc_code VARCHAR (10)
			,loc_desc VARCHAR (50)
			,certification VARCHAR (MAX)
			,cert_area VARCHAR (MAX)
)

INSERT INTO #cert (
             employee_number
			,last_name
			,first_name
			,job_code
			,job_desc
			,loc_code
			,loc_desc
			,certification
			,cert_area
)

SELECT DISTINCT
     c.prce_emp
	,m.prem_lname
	,m.prem_fname
	,m.prem_p_jclass
	,j.prjb_long
	,m.prem_loc
	,l.prln_long
	,certif.prms_long
	,STRING_AGG(RTRIM(area.prms_long),', ')
FROM prempcer c

LEFT JOIN prempmst m ON
c.prce_emp = m.prem_emp AND
m.prem_proj = '0'

LEFT JOIN prjobcls j ON
j.prjb_code = m.prem_p_jclass AND
j.prjb_proj = '0'

LEFT JOIN prlocatn l ON
m.prem_loc = l.prln_code

LEFT JOIN prmisccd certif ON
c.prce_type = certif.prms_code AND
certif.prms_type = 'CERT'

LEFT JOIN prmisccd area ON
c.prce_area = area.prms_code AND
area.prms_type = 'AREA'

WHERE c.prce_proj = '0' AND
c.prce_type IN ('PRF','TMP','ILC','MCRD') AND
m.prem_act_stat NOT IN ('I','M')

GROUP BY  c.prce_emp, m.prem_lname, m.prem_fname, m.prem_p_jclass, j.prjb_long, m.prem_loc, l.prln_long, certif.prms_long

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Contract Table.
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#contr') IS NOT NULL
       DROP TABLE #contr

CREATE TABLE #contr (
                emp_num VARCHAR (10)
			   ,last_name VARCHAR (50)
			   ,first_name VARCHAR (50)
			   ,job_code VARCHAR (10)
			   ,bargain VARCHAR (10)
			   ,bargain_desc VARCHAR (50)
			   ,contract_code VARCHAR (20)
			   ,contract_type VARCHAR (60)
)

INSERT INTO #contr (
               emp_num
			  ,last_name
			  ,first_name
			  ,job_code
			  ,bargain
			  ,bargain_desc
			  ,contract_code
			  ,contract_type
)

SELECT DISTINCT
      m.prem_emp
	 ,CONCAT(LEFT(m.prem_lname, 1) ,RTRIM(LOWER(SUBSTRING(m.prem_lname, 2, 100))))
	 ,CONCAT(LEFT(m.prem_fname, 1) ,RTRIM(LOWER(SUBSTRING(m.prem_fname, 2, 100))))
	 ,m.prem_p_jclass
	 ,m.prem_p_bargain
	 ,b.prbu_long
	 ,CASE WHEN p_contract.c_desc = 'PROFESSIONAL SERVICE CONTRACT' THEN p_contract.c_code
	       ELSE	contract.c_code
	  END AS contract_code
	 ,CASE WHEN	p_contract.c_desc = 'PROFESSIONAL SERVICE CONTRACT' THEN p_contract.c_desc
		   ELSE	contract.c_desc
	  END AS contract_type

FROM prempmst m

LEFT JOIN (SELECT
			 u.prus_emp AS emp_id
			,u.prus_code AS c_code
			,d.LongDescription AS c_desc
		    
		   FROM prempusr u

	       LEFT JOIN HRUserDefinedCodes AS d
		   ON d.Code = u.prus_code

	       WHERE 1=1 AND	
		   u.prus_proj = '0' AND	
		   u.prus_usr_cd = '1200') AS p_contract 
		   ON p_contract.emp_id = m.prem_emp

LEFT JOIN (SELECT
			 u.prus_emp AS emp_id
			,u.prus_code AS c_code
			,d.LongDescription	AS c_desc
		
		   FROM prempusr u

		   LEFT JOIN HRUserDefinedCodes AS d 
		   ON d.Code = u.prus_code

		   WHERE 1=1 AND	
		   u.prus_proj = '0' AND	
		   u.prus_usr_cd = '1220') AS contract 
		   ON contract.emp_id = m.prem_emp
           

LEFT JOIN prlocatn l
ON m.prem_loc = l.prln_code

LEFT JOIN prbargin b 
ON m.prem_p_bargain = b.prbu_code

LEFT JOIN premppay p 
ON m.prem_p_jclass = p.prep_job AND
p.prep_proj = '0'

WHERE prem_proj = '0' AND
m.prem_act_stat NOT IN ('I','M') AND
m.prem_p_bargain BETWEEN '1200' AND '3999' AND
m.prem_p_jclass NOT IN ( '3049' , '3053' , '3058' , '3061' , '3918' ) AND
contract.c_code IS NOT NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- SELECTION
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------



SELECT 
    p.pmpc_position AS pos 
   ,p.pmpc_desc AS pos_desc 
   ,p.pmpc_job_class AS job_code 
   ,RTRIM ( pr_job_class.a_job_class_desc ) AS job_desc 
   ,p.pmpc_bgnu AS bu 
   ,p.pmpc_loc AS loc_code 
   ,IIF ( p.pmpc_freeze = 'Y' , p.pmpc_max_employees , 0 ) AS frozen_units 
   ,IIF ( p.pmpc_freeze = 'N' , p.pmpc_max_employees , 0 ) AS budget_units 
   ,p.pmpc_cy_fte_act AS occupied_units 
   ,p.pmpc_max_employees - p.pmpc_cy_fte_act AS remain_units 
   ,jp.name 
   ,jp.emp_id 
   ,jp.fte
   ,jp.days_year
   ,jp.hours_day 
   ,jp.inst_senior
   ,jp.service_date
   ,#contr.contract_type
   ,#contr.contract_code
   ,jp.emp_status 
   ,jp.pay_status 
   ,#cert.certification
   ,#cert.cert_area
   ,CASE WHEN #s.alloc_code IS NULL THEN gl.fund 
         ELSE #s.fund 
    END AS fund 

FROM pmposctl p

LEFT JOIN 
      (SELECT 
          a_object 
         ,a_project 
         ,a_org 
         ,b_full_account AS fund 
       FROM gl_long_account 

WHERE 1=1 

) AS gl 

 

ON gl.a_object = p.pmpc_obj AND 
gl.a_project = p.pmpc_proja AND 
gl.a_org = p.pmpc_org 

 
LEFT JOIN #s 

ON #s.alloc_code = p.pmpc_cy_alloc 

LEFT JOIN pr_job_class 

ON pr_job_class.a_job_class_code = p.pmpc_job_class AND 
pr_job_class.a_projection = p.pmpc_proj 

 LEFT JOIN 
      (SELECT 
           p.prep_emp AS emp_id 
          ,master.name AS 'name'
          ,p.prep_fte_pct AS fte 
		  ,p.prep_days_per_yr AS days_year
          ,p.prep_dayhrs AS hours_day 
          ,p.prep_start AS date_start 
          ,p.prep_end AS date_end 
          ,p.prep_job AS job_code 
          ,p.prep_pos AS pos_code 
          ,p.prep_inactive AS pay_status 
          ,master.emp_status
          ,master.inst_senior
          ,master.service_date

FROM premppay p 

LEFT JOIN 
      (SELECT 
           m.prem_emp AS emp_id 
          ,CONCAT ( RTRIM ( m.prem_lname ) , ', ' , RTRIM ( m.prem_fname ) , ' ' , RTRIM ( m.prem_minit ) ) AS name 
          ,m.prem_act_stat AS emp_status 
          ,m.prem_perm AS inst_senior
          ,m.prem_service AS service_date

	   FROM prempmst m
       WHERE 1=1 AND 
	   m.prem_proj = 0 AND
	   m.prem_act_stat IN ('A','B') 
      ) AS master 

ON master.emp_id = p.prep_emp 

 WHERE 1=1 AND 
 master.name IS NOT NULL AND 
 p.prep_proj = 0 AND 
 p.prep_base_pay = 'Y'  AND 
 p.prep_inactive != 'I' AND
 p.prep_loc IN (@loc)
) AS jp 

ON jp.pos_code = p.pmpc_position 

LEFT JOIN #contr
ON jp.emp_id = #contr.emp_num

LEFT JOIN #cert
ON jp.emp_id = #cert.employee_number

WHERE 1=1 AND 
p.pmpc_proj = 0 AND
p.pmpc_loc IN (@loc) AND
p.pmpc_status IN (@pstat) AND
>>>>>>> c8cac85d15ad9610f65c5afedc64f7b9d6094a8a
p.pmpc_job_class IN (@jc)