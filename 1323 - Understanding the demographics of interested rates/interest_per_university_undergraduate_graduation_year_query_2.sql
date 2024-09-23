-- --------------- - UNDERGRADUATE GRADUATION YEAR - GROUP BY YEAR  -------------------------

SELECT 
YEAR(end_date),
sum(case when cis.status=1 then 1 else 0 end) as "Interested",
sum(case when cis.status=0 then 1 else 0 end) as "Not interested",
count(*) as "Count of responses",
(sum(case when cis.status=1 then 1 else 0 end)/count(*))*100 as "% Interested",
(sum(case when cis.status=0 then 1 else 0 end)/count(*))*100 as "% Not interested"
FROM candidate_interested_status cis
JOIN caliber_education ce ON cis.candidate_id = ce.caliber_id
JOIN education e ON ce.education_id = e.id
WHERE ce.start_date!= "0000-00-00 00:00:00" -- Exluding null start dates from candidate education
AND ce.end_date!= "0000-00-00 00:00:00"     -- Exluding null end dates from candidate education
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
GROUP BY YEAR(end_date)
ORDER BY YEAR(end_date);

-- ---------------------------------------------------------------------------------------
