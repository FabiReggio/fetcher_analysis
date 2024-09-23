-- Rates per Company by Role Type -- 

SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    r.name as "Role Name",
    (sum(case when bc.contact_status!= 0 then 1 else 0 end)/count(bc.caliber_id)) as contact_rate,
    sum(case when bc.responded = 1 then 1 else 0 end) / sum(case when bc.contact_status >= 1 then 1 else 0 end) as response_rate,
    (sum(case when cis.status=1 then 1 else 0 end)/ sum(case when bc.responded=1 then 1 else 0 end)) as interested_rate

FROM batch_candidates bc
LEFT JOIN positions_batches pb on pb.batch_id=bc.batch_id
LEFT JOIN positions_roles pr on pr.position_id=pb.position_id
LEFT JOIN roles r on r.id=pr.role_id
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pb.position_id
LEFT JOIN positions p ON p.id = pr.position_id 
LEFT JOIN companies co ON co.id = p.company_id 

WHERE 1=1

    AND YEAR(bc.created) >= 2020 
    AND r.name <> "" 
    [[AND co.id = {{company_id}}]]
    [[AND co.name regexp {{company_name}}]]
    [[AND r.name regexp {{role}}]]
    [[AND p.created BETWEEN {{date_initial}} AND {{date_final}}]] 

GROUP BY co.id, r.id
ORDER BY co.id, r.id;
