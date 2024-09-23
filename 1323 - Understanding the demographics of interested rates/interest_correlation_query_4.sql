-- ----------------------------------- QUERY TO CHECK CORRELATION  -----------------------------------------------------

SELECT  
cis.candidate_id,
cg.gender_label as "Gender",
YEAR(ce.end_date) as "Undergraduate Graduation Year",
MIN(YEAR(cc.start_date)) as "First Job Start Date",
e.degree as "Degree",
MIN(YEAR(cc.start_date)) - YEAR(ce.end_date) as "Difference of dates (Years)",
cis.status as "interest_flag"
FROM candidate_interested_status cis
JOIN candidate_gender cg ON cis.candidate_id = cg.candidate_id
JOIN caliber_education ce ON cis.candidate_id = ce.caliber_id
JOIN education e ON ce.education_id = e.id
JOIN caliber_companies cc ON cis.candidate_id = cc.caliber_id
WHERE cg.gender_label!= "unknown"             -- Excluding unknown gender
AND cc.start_date!= "0000-00-00 00:00:00" -- Exluding null start dates from caliber companies
AND cc.position!="" -- Excluding null descriptions from caliber companies
AND ce.start_date!= "0000-00-00 00:00:00"   -- Exluding null start dates from candidate education
AND ce.end_date!= "0000-00-00 00:00:00" -- Exluding null end dates from candidate education
AND e.degree!=""
AND e.field_of_study!= ""
AND e.degree not like '%Master%'
AND e.degree not like '%Mba%' 
AND e.degree not like '%Mfa%' 
AND e.degree not like '%Msc%' 
AND e.degree not like '%Ma%'
AND e.degree not like '%Ms%'
AND e.degree not like '%Mca%'
AND e.degree not like '%M.s.c.s.%' 
AND e.degree not like '%Hsc%'
AND e.degree not like '%High School%' 
AND e.degree not like '%Higher Secondary%' 
AND e.degree not like '%Secondary School%' 
AND e.degree not like '%Secondary Education%' 
AND e.degree not like '%Phd%' 
AND e.degree not like '%Postgraduation%' 
AND e.degree not like '%Postgraduate%' 
AND e.degree not like '%Doctorate%'
AND e.degree not like '%Doctor%'
AND e.degree not like '%Bootcamp%'
AND e.degree not like '%Unfinished%'
AND (YEAR(ce.end_date) - YEAR(ce.start_date))>3 -- To ensure careers with more than 3 years
GROUP BY cis.candidate_id
ORDER BY cis.candidate_id;

-- ---------------------------------------------------------------------------------------------------------------------