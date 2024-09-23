SELECT
cis.contacted_status as "Touchpoint",
sum(case when cis.status=1 then 1 else 0 end) as "Interested",
sum(case when cis.status=0 then 1 else 0 end) as "Not interested",
count(*) as "Count of responses",
(sum(case when cis.status=1 then 1 else 0 end)/count(*))*100 as "% Interested",
(sum(case when cis.status=0 then 1 else 0 end)/count(*))*100 as "% Not interested"
FROM candidate_interested_status cis
JOIN candidate_message cm ON cm.id = cis.message_id -- MATCH BETWEEN candidate_interested_status and candidate_message to ensure there exists the message
JOIN candidate_thread_messages ctm ON cm.id = ctm.thread_id -- MATCH BETWEEN candidate_thread_messages and candidate_message to ensure the thread of messages
WHERE cis.contacted_status >=1 
GROUP BY cis.contacted_status
ORDER BY cis.contacted_status;
