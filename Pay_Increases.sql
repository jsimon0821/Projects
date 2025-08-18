--Combines employee information across from many tables to produce potential pay raises based on given rates by the state.


-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a calendar description table
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#cal') IS NOT NULL  
	DROP TABLE #cal

SELECT DISTINCT
	RTRIM ( prcalhdr.prch_code ) 	AS cal_code
	,RTRIM ( prch_long )	AS cal_desc
INTO 
	#cal
FROM
	prcalhdr

INNER JOIN
	(SELECT
		prcalhdr.prch_code	AS cal_code
		,MAX ( prcalhdr.prch_cal_end ) AS recent_date
	FROM
		prcalhdr
	GROUP BY
		prcalhdr.prch_code
	) AS recent_calendar
ON
	recent_calendar.cal_code = prcalhdr.prch_code
AND	recent_calendar.recent_date = prcalhdr.prch_cal_end

INSERT INTO #cal ( cal_code , cal_desc ) 	VALUES ( NULL , 'No Calendar' )

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Grade Descriptions 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#grade') IS NOT NULL  
	DROP TABLE #grade

SELECT DISTINCT
	RTRIM ( pmgrtabl.pmgr_grade ) 	AS grade
	,RTRIM ( pmgrtabl.pmgr_desc ) 	AS grade_desc
INTO 
	#grade

FROM
	pmgrtabl

INNER JOIN
	(SELECT 
		RTRIM ( pmgrtabl.pmgr_grade ) 	AS grade
		,MAX ( pmgrtabl.pmgr_date )	AS max_date
	FROM	
		pmgrtabl

	WHERE	1=1
	AND	pmgrtabl.pmgr_proj = 0

	GROUP BY
		pmgrtabl.pmgr_grade
	) AS g_max
ON
	g_max.grade = pmgrtabl.pmgr_grade
AND	g_max.max_date = pmgrtabl.pmgr_date

WHERE	1=1
AND	pmgrtabl.pmgr_proj = 0

INSERT INTO #grade ( grade , grade_desc ) 	VALUES ( NULL , 'No Grade' )
	

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Pay Type Table 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#pt0') IS NOT NULL  
	DROP TABLE #pt0

SELECT DISTINCT
	premppay_all.prep_pay	AS pay_type
	,pay_type.pay_desc
	,CASE	WHEN	premppay_all.prep_bgnu < '1600'	THEN 	1
		ELSE 0
	END AS flag_admin
	,CASE	WHEN	premppay_all.prep_bgnu BETWEEN '1600' AND '1999'	THEN 	1
		ELSE 0
	END AS flag_protech
	,CASE	WHEN	premppay_all.prep_bgnu BETWEEN '2000' AND '2999'	THEN 	1
		ELSE 0
	END AS flag_inst
	,CASE	WHEN	premppay_all.prep_bgnu BETWEEN '3000' AND '3999'	THEN 	1
		ELSE 0
	END AS flag_nnb
	,CASE	WHEN	premppay_all.prep_bgnu BETWEEN '4000' AND '4999'	THEN 	1
		ELSE 0
	END AS flag_srp
INTO 
	#pt0
FROM
	premppay_all

LEFT JOIN
	(SELECT
		prpaytyp.prpt_code AS pay_type
		,RTRIM ( prpaytyp.prpt_long )	AS pay_desc
	FROM
		prpaytyp
	WHERE	1=1
	AND	prpaytyp.prpt_proj = 0
	
	) AS pay_type
ON
	pay_type.pay_type = premppay_all.prep_pay

WHERE	1=1
AND	premppay_all.prep_proj = 0
AND (	@base_pay = 1
AND	premppay_all.prep_pay IN ( 100 , 101 , 105 , 108 , 110 , 115 , 160 , 161 , 162 , 190 )
OR  (	@base_pay = 0
AND	premppay_all.prep_pay IN ( 100 , 101 , 105 , 108 , 110 , 115 , 160 , 161 , 162 , 190 , 230 , 280 , 285 , 444 , 493 , 530 , 531 , 532 , 533 , 534 , 540 , 555 , 561 , 562 , 563 , 564 , 565 , 566 , 567 , 581 , 591 , 592 , 593 , 594 , 595 , 596 , 599 , 603 , 604 , 605 , 606 , 608 , 609 , 610 , 611 , 612 , 615 , 616 , 617 , 618 , 620 , 628 , 629 , 631 , 632 , 634 , 636 , 637 , 638 , 641 , 643 , 644 , 645 , 650 , 651 , 653 , 654 , 655 , 656 , 657 , 658 , 663 , 664 , 665 , 666 , 667 , 668 , 669 , 670 , 672 , 673 , 676 , 677 , 680 , 682 , 683  )
) )

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Pay Type Table Part 2 Getting it down to 1 record per pay_type
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#pt') IS NOT NULL  
	DROP TABLE #pt

SELECT 
	pay_type
	,pay_desc
	,MAX ( flag_admin ) 	AS flag_admin
	,MAX ( flag_protech ) 	AS flag_protech
	,MAX ( flag_inst ) 	AS flag_inst
	,MAX ( flag_nnb ) 	AS flag_nnb
	,MAX ( flag_srp ) 	AS flag_srp
INTO
	#pt
FROM
	#pt0

GROUP BY
	pay_type
	,pay_desc

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Master Table 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#m') IS NOT NULL  
	DROP TABLE #m

SELECT
	CAST ( prempmst.prem_emp AS VARCHAR (10) )	AS emp_id	
	,RTRIM ( prempmst.prem_lname )	AS namel	
	,RTRIM ( prempmst.prem_fname )	AS namef
	,RTRIM ( prempmst.prem_minit )	AS namemi
	,prempmst.prem_act_stat 	AS emp_status
	,prempmst.prem_p_bargain	AS m_bu	
	,prempmst.prem_service	AS date_service	
	,prempmst.prem_perm	AS date_permanent
	,CASE 	WHEN	prempmst.prem_perm IS NULL AND prempmst.prem_p_bargain BETWEEN '2000' AND '2999'	THEN 	''
		WHEN	prempmst.prem_p_bargain BETWEEN '2000' AND '2999'	THEN	prempmst.prem_perm
		WHEN	prempmst.prem_service IS NULL 	THEN 	'' 
	ELSE	prempmst.prem_service  
	END	AS date_senority
	,prempmst.prem_inact	AS inactive_code	
	,prempmst.prem_inact_date	AS inactive_date	
	,RTRIM ( inac.prms_long )	AS inactive_desc	
	,prempmst.prem_term	AS term_code	
	,prempmst.prem_term_date	AS term_date	
	,RTRIM ( term.prms_long	) AS term_desc	
	,CASE	WHEN	RTRIM (p_contract.c_desc ) = 'PROFESSIONAL SERVICE CONTRACT' 	THEN	p_contract.c_desc
	ELSE	contract.c_desc
	END	AS contract_type
	,pay_plan.c_desc  AS pay_plan

INTO
	#m
FROM
	prempmst

LEFT JOIN
	(SELECT
		prempusr.prus_emp 
		,prempusr.prus_usr_cd	AS c_code
		,d.LongDescription	AS c_desc		
	FROM
		prempusr

	LEFT JOIN
		HRUserDefinedCodes AS d
	ON
		d.Code = prempusr.prus_code

	WHERE	1=1
	AND	prempusr.prus_usr_cd = '1230' 
	AND	prempusr.prus_proj = 0
	) AS pay_plan
ON
	pay_plan.prus_emp  = prempmst.prem_emp

LEFT JOIN 
	(SELECT
		prempusr.prus_emp 	AS emp_id
		,prempusr.prus_usr_cd	AS c_code
		,d.LongDescription	AS c_desc
	FROM
		prempusr

	LEFT JOIN
		HRUserDefinedCodes AS d
	ON
		d.Code = prempusr.prus_code

	WHERE	1=1
	AND	prempusr.prus_proj = 0
	AND	prempusr.prus_usr_cd = '1200'
	) AS p_contract
ON
	p_contract.emp_id = prempmst.prem_emp

LEFT JOIN 
	(SELECT
		prempusr.prus_emp 	AS emp_id
		,prempusr.prus_usr_cd	AS c_code
		,d.LongDescription	AS c_desc
	FROM
		prempusr

	LEFT JOIN
		HRUserDefinedCodes AS d
	ON
		d.Code = prempusr.prus_code

	WHERE	1=1
	AND	prempusr.prus_proj = 0
	AND	prempusr.prus_usr_cd = '1220'
	) AS contract
ON
	contract.emp_id = prempmst.prem_emp


LEFT JOIN
	prmisccd AS inac
ON
	inac.prms_code = prempmst.prem_inact
AND	inac.prms_type = 'INAC'

LEFT JOIN
	prmisccd AS term
ON
	term.prms_code = prempmst.prem_term
AND	term.prms_type = 'INAC'

WHERE	1=1
AND	prempmst.prem_proj = 0
AND	prempmst.prem_act_stat IN ( 'A' , 'B' )
AND	prempmst.prem_p_bargain BETWEEN '1200' AND '4999'

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create a Job Pay Table 
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#jp') IS NOT NULL  
	DROP TABLE #jp

SELECT DISTINCT
	CAST ( premppay_all.prep_emp AS VARCHAR (10) )	AS emp_id
	,premppay_all.prep_grade AS grade
	,premppay_all.prep_job	AS job_code
	,premppay_all.prep_step AS step
	,premppay_all.prep_hrly_rt1	AS rate_hourly
                ,premppay_all.prep_per_sal1     AS rate_biweekly
	,premppay_all.prep_ann_sal1	AS rate_annual
	,premppay_all.prep_pay	AS pay_type
	,premppay_all.prep_pos	AS pos_code
	,premppay_all.prep_loc	AS loc_code
	,premppay_all.prep_bgnu	AS bu
	,CASE	WHEN	premppay_all.prep_bgnu < '1600'	THEN 	'Admin'
		WHEN	premppay_all.prep_bgnu < '2000'	THEN	'Pro-Tech'
		WHEN	premppay_all.prep_bgnu < '3000'	THEN	'Instructional'
		WHEN	premppay_all.prep_bgnu < '4000'	THEN	'NNB'
		WHEN	premppay_all.prep_bgnu < '5000'	THEN 	'SRP'
	ELSE	'OTHER'
	END	AS bu_group
	,premppay_all.prep_start	AS date_start
	,premppay_all.prep_end	AS date_end
	,premppay_all.prep_step_date	AS date_effective
	,premppay_all.prep_days_per_yr	AS days_yr
	,premppay_all.prep_hrs_per_yr	AS hours_yr
	,premppay_all.prep_dayhrs	AS hours_day
	,premppay_all.prep_fte_pct	AS fte
	,CASE	WHEN	(premppay_all.prep_frozen = 'O') 	THEN	('Offstep')
		WHEN 	(premppay_all.prep_frozen = 'F')	THEN 	('Frozen')
		WHEN 	(premppay_all.prep_frozen = 'M')	THEN 	('Mid Year')
		WHEN 	(premppay_all.prep_frozen = 'N')	THEN 	('Not Any')
	ELSE 	premppay_all.prep_frozen
	END AS frozen
	,premppay_all.prep_inactive	AS pay_status
	,premppay_all.prep_work_st_dt	AS date_start_wk
	,premppay_all.prep_work_end_dt	AS date_end_wk
	,RTRIM ( premppay_all.prep_civ_desig )	AS civil_designation
	,RTRIM ( premppay_all.prep_civ_de_stat )	AS civil_designation_status
	,CASE	WHEN	( premppay_all.prep_pay < '200' )	THEN	('Base Pay')
	ELSE	('Supp')	
	END AS Base_pay
	,premppay_all.prep_calndr	AS cal_code
	,premppay_all.prep_org	AS g_org	
	,premppay_all.prep_d_proj	AS g_proj	
	,premppay_all.prep_obj	AS g_obj

	,RTRIM ( pmposctl.pmpc_desc )	AS pos_desc
	,RTRIM ( prjobcls.prjb_long )	AS job_desc
	,RTRIM ( loc.prln_long	) 	AS loc_desc	
	,RTRIM ( #pt.pay_desc ) AS pay_desc
	,RTRIM ( #grade.grade_desc ) AS grade_desc
	,RTRIM ( #cal.cal_desc ) AS cal_desc
	,jp.date_effective_end
	,prjobcls.prjb_cat2	AS job_code_status
	,prjobcls.prjb_teacher	AS flag_classroom
	,prjobcls.prjb_state_pos	AS job_code_state_position

INTO
	#jp
FROM 
	premppay_all

LEFT JOIN
	(SELECT
		CAST ( premppay_all.prep_emp AS VARCHAR (10) )	AS emp_id
		,premppay_all.prep_pos 	AS pos_code
		,premppay_all.prep_pay	AS pay_type
		,premppay_all.prep_step_date	AS date_effective
		,DATEADD ( DAY , -1 , LEAD ( premppay_all.prep_step_date ) 
			OVER ( 
			PARTITION BY  premppay_all.prep_emp , premppay_all.prep_pos , premppay_all.prep_pay
			ORDER BY  premppay_all.prep_step_date )  ) AS date_effective_end
	FROM
		premppay_all
	WHERE	1=1
	AND	premppay_all.prep_proj = 0
	AND	premppay_all.prep_end > @end_date
	AND	premppay_all.prep_bgnu BETWEEN '1200' AND '4999'
	AND	premppay_all.prep_step_date < = GETDATE ()
	) AS jp
ON
	jp.emp_id = premppay_all.prep_emp
AND	jp.pos_code = premppay_all.prep_pos
AND	jp.pay_type = premppay_all.prep_pay
AND	jp.date_effective = premppay_all.prep_step_date

LEFT JOIN
	pmposctl
ON
	pmposctl.pmpc_position = premppay_all.prep_pos
AND	pmposctl.pmpc_proj = premppay_all.prep_proj

LEFT JOIN
	(SELECT
		prlocatn.prln_code
		,prlocatn.prln_long

	FROM
		prlocatn
	) AS loc
ON 
	loc.prln_code = premppay_all.prep_loc

LEFT JOIN
	prjobcls
ON
	prjobcls.prjb_code = premppay_all.prep_job
AND	prjobcls.prjb_proj = premppay_all.prep_proj

INNER JOIN
	#pt
ON
	#pt.pay_type = premppay_all.prep_pay

LEFT JOIN	
	#grade
ON
	#grade.grade = premppay_all.prep_grade

LEFT JOIN 
	#cal
ON 
	#cal.cal_code = premppay_all.prep_calndr
		
WHERE	1=1
AND	premppay_all.prep_proj = 0
AND	premppay_all.prep_end > @end_date
AND	premppay_all.prep_bgnu BETWEEN '1200' AND '4999'
AND	premppay_all.prep_step_date < = '1/1/2025'
AND	(jp.date_effective_end IS NULL OR
                 jp.date_effective_end > @end_date)


IF OBJECT_ID('tempdb..#gl') IS NOT NULL  
	DROP TABLE #gl

SELECT
	pmposctl.pmpc_position								AS pos_code
	,RTRIM ( pmposctl.pmpc_desc )							AS pos_desc
	,pmposctl.pmpc_proj								AS proj
	,gl.account_strip 
	,gl.account_desc
	,gl.object_code
	,gl.project_code
	,gl.org_code

INTO
	#gl

FROM
	pmposctl

LEFT JOIN
	(SELECT
		gl_long_account.a_object 		AS object_code
		,gl_long_account.a_project		AS project_code
		,gl_long_account.a_org			AS org_code
		,gl_long_account.b_full_account		AS account_strip
		,gl_long_account.a_account_desc		AS account_desc
	FROM
		gl_long_account
	WHERE	1=1
		) AS gl
ON
	gl.object_code = pmposctl.pmpc_obj
AND	gl.project_code = pmposctl.pmpc_proja
AND	gl.org_code = pmposctl.pmpc_org

WHERE	1=1
AND	pmposctl.pmpc_proj = 0
AND	pmposctl.pmpc_max_employees > 0


-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Create Temp Table for Position Funding
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#gl2') IS NOT NULL  
	DROP TABLE #gl2

SELECT 
	#gl.pos_code
	,#gl.pos_desc
	,#gl.proj
	,#gl.account_strip
	,#gl.object_code
	,o.object_desc
	,#gl.project_code
	,p.project_desc
	,#gl.org_code
	,g.account_type

INTO
	#gl2
FROM 
	#gl

LEFT JOIN
	(SELECT
		gl_long_account_2.a_object		AS object_code
		,gl_long_account_2.a_project		AS project_code
		,gl_long_account_2.a_org		AS org_code
		,gl_long_account_2.a_account_type	AS account_type
	FROM
		gl_long_account_2
	WHERE	1=1

	) AS g
ON
	g.org_code = #gl.org_code
AND	g.project_code = #gl.project_code
AND	g.object_code = #gl.object_code

LEFT JOIN
	(SELECT 
		pamaster.pama_proj	AS project_code
		,pamaster.pama_title	AS project_desc
	FROM
		pamaster
	WHERE	1=1
	) AS p
ON
	p.project_code = #gl.project_code

LEFT JOIN
	(SELECT
		glob_object	AS object_code
		,glob_desc	AS object_desc
	FROM 
		globject
	WHERE	1=1
	) AS o
ON
	o.object_code = #gl.object_code

-----------------------------------------------------------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Add master & Position field and filter by @bu_group
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-----------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#emp') IS NOT NULL  
	DROP TABLE #emp

SELECT DISTINCT
	#jp.emp_id
	,#jp.grade
	,#jp.job_code
	,#jp.step
	,#jp.rate_hourly
                ,#jp.rate_biweekly
	,#jp.rate_annual
	,#jp.pay_type
	,#jp.pos_code
	,#jp.pos_desc
	,#jp.loc_code
	,#jp.bu
	,#jp.bu_group
	,#jp.date_start
	,#jp.date_end
	,#jp.date_effective
	,#jp.days_yr
	,#jp.hours_yr
	,#jp.hours_day
	,#jp.fte
	,#jp.frozen
	,#jp.pay_status
	,#jp.date_start_wk
	,#jp.date_end_wk
	,#jp.civil_designation
	,#jp.civil_designation_status
	,#jp.Base_pay
	,#jp.cal_code
	,#jp.job_desc
	,#jp.loc_desc	
	,#jp.pay_desc
	,#jp.grade_desc
	,#jp.cal_desc
	,#jp.flag_classroom
	,#jp.job_code_state_position
	
	,#m.namel
	,#m.namef
	,#m.namemi
	,#m.emp_status
	,#m.m_bu
	,#m.date_service
	,#m.date_permanent	
	,#m.date_senority	
	,#m.inactive_code 
	,#m.inactive_date
	,#m.inactive_desc
	,#m.term_code 
	,#m.term_date 
	,#m.term_desc
	,#m.contract_type
	,#m.pay_plan

	,#gl2.object_code
	,#gl2.object_desc
	,#gl2.project_code
	,#gl2.project_desc
	,#gl2.account_type
	,#gl2.account_strip

	,CASE	WHEN	#jp.bu_group != 'Instructional'	THEN	0
		WHEN	#jp.fte IS NULL		THEN	0
		WHEN	#jp.fte = 0 		THEN 	0
		WHEN	#jp.days_yr IS NULL	THEN 	0
		WHEN	#jp.days_yr = 0		THEN 	0
		WHEN	#jp.hours_day IS NULL	THEN	0
		WHEN	#jp.hours_day = 0 	THEN 	0
		ELSE	( ( #jp.rate_annual / #jp.fte ) / #jp.days_yr ) / #jp.hours_day				
	END AS pay_fte
	,CASE	WHEN	#jp.bu_group != 'Instructional'	THEN	0
		WHEN	#jp.fte IS NULL		THEN	0
		WHEN	#jp.fte = 0 		THEN 	0
		WHEN	#jp.days_yr IS NULL	THEN 	0
		WHEN	#jp.days_yr = 0		THEN 	0
		WHEN	#jp.hours_day IS NULL	THEN	0
		WHEN	#jp.hours_day = 0 	THEN 	0
		ELSE	( ( ( #jp.rate_annual / #jp.fte ) / #jp.days_yr ) / #jp.hours_day ) * 196 * 7.5		
	END AS pay_fte_196_7_5

INTO
	#emp
FROM
	#jp

LEFT JOIN
	#m
ON
	#m.emp_id = #jp.emp_id

LEFT JOIN
	#gl2
ON
	#gl2.pos_code = #jp.pos_code

WHERE	1=1
AND	#m.emp_id IS NOT NULL
AND	#jp.bu_group IN (@bu)

SELECT * FROM #emp
WHERE	1=1
AND	job_code NOT IN ( '3049' , '3053' , '3058' , '3061' , '3819' )

ORDER BY 
	emp_id
	,pay_type