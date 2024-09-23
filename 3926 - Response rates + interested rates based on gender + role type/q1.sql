-- 3926 - (Response, Interest, Contact) Rates by Role -- 

SELECT 
    r.name as "Role Name",
    (sum(case when bc.contact_status!= 0 then 1 else 0 end)/count(bc.caliber_id)) as contact_rate,
    sum(case when bc.responded = 1 then 1 else 0 end) / sum(case when bc.contact_status >= 1 then 1 else 0 end) as response_rate,
    (sum(case when cis.status=1 then 1 else 0 end)/ sum(case when bc.responded=1 then 1 else 0 end)) as interested_rate
FROM batch_candidates bc
LEFT JOIN positions_batches pb on pb.batch_id=bc.batch_id
LEFT JOIN positions_roles pr on pr.position_id=pb.position_id
LEFT JOIN roles r on r.id=pr.role_id
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pb.position_id
WHERE 1=1
AND YEAR(bc.created) >= 2020 AND DATE(bc.created) < DATE(CURDATE() - INTERVAL 2 MONTH) 
AND r.name <> ""
[[AND r.name regexp {{role}}]]
GROUP BY r.id
ORDER BY response_rate desc;