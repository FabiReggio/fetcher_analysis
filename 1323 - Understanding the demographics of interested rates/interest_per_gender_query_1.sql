-- --------------------------- - GENDER - GROUP BY GENDER  --------------------------------


SELECT 
cg.gender_label as "Gender",
sum(case when cis.status=1 then 1 else 0 end) as "Interested",
sum(case when cis.status=0 then 1 else 0 end) as "Not interested",
count(*) as "Count of responses",
(sum(case when cis.status=1 then 1 else 0 end)/count(*))*100 as "% Interested",
(sum(case when cis.status=0 then 1 else 0 end)/count(*))*100 as "% Not interested"
FROM candidate_interested_status cis
JOIN candidate_gender cg ON cis.candidate_id = cg.candidate_id
GROUP BY cg.gender_label
ORDER BY count(*) DESC;

-- ---------------------------------------------------------------------------------------