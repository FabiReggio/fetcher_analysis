-- Number of candidates interested by Customer Company --

SELECT 
    co.id as "Company ID",
    co.name as "Company Name",
    sum(case when cis.status=1 then 1 else 0 end) as "Interested",
    sum(case when cis.status=0 then 1 else 0 end) as "Not Interested",
    sum(case when cis.status=1 then 1 else 0 end) / sum(case when bc.responded=1 then 1 else 0 end) as "% Interested",
    sum(case when cis.status=0 then 1 else 0 end) / sum(case when bc.responded=1 then 1 else 0 end) as "% Not Interested",
    count(distinct bc.caliber_id) as "Leads Sent"
    
FROM customer_companies as cc
LEFT JOIN companies co on cc.company_id = co.id
-- BATCHES DATA 
LEFT JOIN positions_side_owners as pso on pso.caliber_id = cc.caliber_id and pso.is_owner = 1
LEFT JOIN positions_batches pb ON pso.position_id = pb.position_id 
LEFT JOIN batch_candidates bc ON bc.batch_id = pb.batch_id         
LEFT JOIN batches as b on b.id = bc.batch_id
-- INTERESTED CANDIDATES DATA
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pso.position_id  
-- POSITIONS DATA
LEFT JOIN positions p ON pso.position_id = p.id AND p.status = 2 
WHERE 1=1
    AND pso.position_id is not NULL
    AND b.status = 2 -- BATCH STATUS: SENT
    [[AND co.id = {{company_id}}]]
    [[AND co.name regexp {{company_name}}]]
    [[AND p.id={{position_id}}]]
    [[AND p.created BETWEEN {{date_initial}} AND {{date_final}}]]
GROUP BY 
    co.id -- GROUP BY COMPANY_ID
ORDER BY 
    count(distinct bc.caliber_id) desc; 