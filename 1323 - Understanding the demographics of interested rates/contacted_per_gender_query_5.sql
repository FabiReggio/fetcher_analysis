-- Query grouping by gender, counting responses of contacted candidates that responded and not responded when the email was sent to a candidate --

SELECT 
cg.gender_label as "Gender",
sum(case when bc.responded=1 then 1 else 0 end) as "Responded",
sum(case when bc.responded=0 then 1 else 0 end) as "Not responded",
count(*) as "Sent Email Count",
(sum(case when bc.responded=1 then 1 else 0 end)/count(*))*100 as "% Responded",
(sum(case when bc.responded=0 then 1 else 0 end)/count(*))*100 as "% Not Responded"
FROM batch_candidates bc 
JOIN candidate_gender cg ON cg.candidate_id = bc.caliber_id
JOIN candidate_events ce ON ce.caliber_id = bc.caliber_id AND ce.batch_id = bc.batch_id
JOIN candidate_event_types cet ON cet.id = ce.event_id -- MATCH BETWEEN candidate_events and candidate_event_types
WHERE bc.status = 3 -- Candidate status contacted
AND cg.gender_label!= "unknown" -- Exclude unknown gender
AND contact_date != "0000-00-00 00:00:00" -- Excluding null contact_date 
AND cet.description = "Email sent" -- Email sent
GROUP by cg.gender_label;