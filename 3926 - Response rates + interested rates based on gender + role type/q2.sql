-- 3926 - Response, Interest and Contact Rates by sender's sex global (all roles) --

SELECT 
cg.gender_label as " Sender Gender",
(sum(case when bc.contact_status!= 0 then 1 else 0 end)/count(bc.caliber_id)) as contact_rate,
sum(case when bc.responded = 1 then 1 else 0 end) / sum(case when bc.contact_status >= 1 then 1 else 0 end) as response_rate,
(sum(case when cis.status=1 then 1 else 0 end)/ sum(case when bc.responded=1 then 1 else 0 end)) as interested_rate
FROM candidate_message email
LEFT JOIN candidate_gender cg on cg.candidate_id = email.from_id 
LEFT JOIN batch_candidates bc on bc.caliber_id = email.to_id
LEFT JOIN positions_batches pb on pb.batch_id=bc.batch_id
LEFT JOIN positions_roles pr on pr.position_id=pb.position_id
LEFT JOIN roles r on r.id=pr.role_id
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pb.position_id
WHERE 1=1
AND r.name <> ""
AND cg.gender_label <> "unknown"
AND YEAR(bc.created) >= 2020 AND DATE(bc.created) < DATE(CURDATE() - INTERVAL 2 MONTH) 
AND email.email_type = 9 -- Response Type
GROUP by cg.gender_label;
