/*
	THE ORIGINAL
*/
SELECT
	p.id AS 'pid',
	p.name AS 'position',
	c. `name` AS 'company',
	CASE WHEN p.status = 1 THEN
		'New'
	WHEN p.status = 2 THEN
		'Open'
	WHEN p.status = 3 THEN
		'Closed'
	WHEN p.status = 4 THEN
		'On hold'
	END AS 'status',
	sum(case event_id when 101 then 1 else 0 end) as fetcher_leads, 
	sum(case event_id when 114 then 1 else 0 end) as extension_leads
FROM
	positions p
	JOIN positions_batches pb ON pb.position_id = p.id
	JOIN positions_side_owners pso ON pso.is_owner = 1
		AND pso.position_id = p.id
	JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
	JOIN companies c ON c.id = cc.company_id
	JOIN batches b ON b.id = pb.batch_id
	JOIN candidate_events ce ON pb.position_id = ce.position_id
		AND ce.batch_id = b.id
WHERE
	b.status = 2
	AND b.`type` in (1,3)
	AND YEAR(ce.created) = {{year}}
	AND MONTH(ce.created) = {{month}}
	AND DAY(ce.created) <= {{day}}
	AND ce.event_id IN(114, 101)
GROUP by p.id