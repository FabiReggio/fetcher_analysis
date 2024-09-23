-- Days until first candidate is disliked --

SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    c.id as "Contract Id",
    TIMESTAMPDIFF(DAY,c.start_date,min(ce.created)) AS "Days until first candidate is disliked" -- ce.created - contract start date
FROM contracts c
LEFT JOIN customer_companies as cc on cc.company_id = c.company_id AND cc.caliber_id = c.customer_id -- NEW: MATCH BETWEEN customer_companies and contracts 
LEFT JOIN companies co ON co.id = c.company_id -- MATCH BETWEEN contracts and companies
 -- BATCHES DATA 
LEFT JOIN positions_side_owners as pso on pso.caliber_id = cc.caliber_id -- JOIN between PSO and customer_companies caliber_id 
LEFT JOIN positions_batches pb ON pso.position_id = pb.position_id -- JOIN between positions_side_owners and positions_batches
LEFT JOIN batch_candidates bc ON bc.batch_id = pb.batch_id         -- JOIN between batch_candidates and positions_batches
LEFT JOIN batches as b on b.id = bc.batch_id
-- CANDIDATE events
LEFT JOIN candidate_events ce ON ce.batch_id = b.id AND ce.caliber_id = bc.caliber_id AND ce.position_id = pso.position_id and ce.created between c.start_date and c.end_date -- JOIN between CE and batches, candidates, positions
WHERE 1=1
    AND b.status = 2 -- BATCH STATUS: SENT
    AND ce.event_id = 202 -- DISLIKE
    [[AND c.company_id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
GROUP BY 
    co.id -- GROUPED BY COMPANY ID
ORDER BY 
    co.name, b.created, bc.created, ce.created;
