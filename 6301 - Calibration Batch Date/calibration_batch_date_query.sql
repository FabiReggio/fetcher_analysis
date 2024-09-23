SELECT 
    p.id AS "Position ID"
    , p.name AS "Position Name"
    , case 
      when p.outreach_type=0
        then 'Fetcher Search'
      when p.outreach_type=1
        then 'Campaign' 
     end as search_type
    , c.name AS "Company Name"
    , concat(p_owner.first_name, ' ', p_owner.last_name) AS "Position Owner"
    , p.created AS "Position Created"
    , MIN(b.modified) AS "First Batch Sent Date"
FROM positions p 
LEFT JOIN companies c ON p.company_id = c.id
LEFT JOIN positions_batches pb ON pb.position_id = p.id
LEFT JOIN batches b ON b.id = pb.batch_id
LEFT JOIN customer_companies cc ON cc.company_id = c.id 
LEFT JOIN positions_side_owners pso ON
		pso.caliber_id = cc.caliber_id
		AND pso.position_id = p.id
		AND pso.is_owner = 1
LEFT JOIN calibers AS p_owner ON p_owner.id = pso.caliber_id
WHERE 1=1
AND pso.position_id IS NOT NULL
AND b.status = 2
[[AND p.id = {{position_id}}]]
[[AND c.id = {{company_id}}]]
[[and p.created between {{start_date}} and {{end_date}}]] 
GROUP BY p.id -- Grouped By: Position ID
ORDER BY p.id DESC; -- Ordered by Most Recent Position 
