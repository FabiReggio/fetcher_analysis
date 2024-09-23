-- Days until first batch is sent --

SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    c.id as "Contract Id",
    TIMESTAMPDIFF(DAY,c.start_date,min(b.modified)) AS "Days until first batch is sent" -- batch modified - contract start date
FROM contracts c
    LEFT JOIN customer_companies as cc on cc.company_id = c.company_id AND cc.caliber_id = c.customer_id -- NEW: MATCH BETWEEN customer_companies and contracts 
    LEFT JOIN companies co ON co.id = c.company_id -- MATCH BETWEEN contracts and companies
    -- BATCHES DATA 
    LEFT JOIN positions_side_owners as pso on pso.caliber_id = cc.caliber_id -- JOIN between PSO and customer_companies caliber_id 
    LEFT JOIN positions_batches pb ON pso.position_id = pb.position_id -- JOIN between positions_side_owners and positions_batches
    LEFT JOIN batches as b on b.id = pb.batch_id and b.modified between c.start_date and c.end_date -- Considering batches between start and end date of a contract (remove negatives)
WHERE 1=1
    AND b.status = 2 -- BATCH STATUS: SENT
    [[AND c.company_id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
GROUP BY 
    co.id -- GROUPED BY COMPANY ID
ORDER BY 
    co.name, c.start_date, b.created; 
