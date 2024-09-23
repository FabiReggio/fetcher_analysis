SELECT 
co.id as "Company Id",
co.name as "Company Name",
case 
    when co.status = 1 then 'Active' 
    when co.status = 2 then 'Canceled'
end as "Company Status",
sum(case when ce.event_id = 405 then 1 else 0 end) as "# Hires"
FROM customer_companies cc
LEFT JOIN companies co ON co.id = cc.company_id    
LEFT JOIN positions_side_owners AS pso ON pso.caliber_id = cc.caliber_id AND pso.is_owner = 1
LEFT JOIN positions_batches AS pb ON pb.position_id = pso.position_id
LEFT JOIN batch_candidates AS bc ON bc.batch_id = pb.batch_id
LEFT JOIN candidate_events ce ON
	ce.caliber_id = bc.caliber_id
	AND ce.batch_id = bc.batch_id
	AND ce.position_id = pb.position_id
	-- AND ce.event_id = 405 -- Hired
WHERE 1=1
AND ce.event_id = 405 -- Hired
[[AND co.id = {{company_id}}]]
[[AND co.name = {{company_name}}]]
[[AND co.status = {{company_status}}]]
GROUP BY
	cc.company_id
ORDER BY
    co.status, sum(case when ce.event_id = 405 then 1 else 0 end) desc;