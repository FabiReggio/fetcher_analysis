-- ---------------------- - TIME OF FIRST JOB - GROUP BY YEAR  ---------------------------


SELECT 
MIN(YEAR(cc.start_date)),
sum(case when cis.status=1 then 1 else 0 end) as "Interested",
sum(case when cis.status=0 then 1 else 0 end) as "Not interested",
count(*) as "Count of responses",
(sum(case when cis.status=1 then 1 else 0 end)/count(*))*100 as "% Interested",
(sum(case when cis.status=0 then 1 else 0 end)/count(*))*100 as "% Not interested"
FROM candidate_interested_status cis
JOIN caliber_companies cc ON cis.candidate_id = cc.caliber_id
WHERE cc.start_date!= "0000-00-00 00:00:00" -- Exluding null start dates
AND cc.position!="" -- Excluding null descriptions
GROUP BY YEAR(cc.start_date)
ORDER BY MIN(YEAR(cc.start_date));

-- ---------------------------------------------------------------------------------------