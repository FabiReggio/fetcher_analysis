SELECT 
c.company_id as "Company ID",
co.name as "Company Name",
-- CONTRACTS METRICS
c.start_date as "Contract Start Date", 
ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as 'Contract End date',
ct.managed_leads_used as 'Fetcher Leads Used ',
ct.managed_leads_paid as 'Fetcher Leads In contract',
concat(format((ct.managed_leads_used / ct.managed_leads_paid)*100,0),"%") as "% Fetcher Leads Used",
ct.self_served_leads_used as 'Extension Leads Used',
ct.self_served_leads_paid as 'Extension Leads In contract',
concat(format((ct.self_served_leads_used / ct.self_served_leads_paid)*100,0),"%") as "% Extension Leads Used",
-- BATCHES METRICS
sum(case when bc.liked = 1 then 1 else 0 end) as "liked",
concat(format((sum(case when bc.liked = 1 then 1 else 0 end)/count(*))*100,0),"%") as "%_liked",
sum(case when bc.liked = 2 then 1 else 0 end) as "disliked",
concat(format((sum(case when bc.liked = 2 then 1 else 0 end)/count(*))*100,0),"%") as "%_disliked",
sum(case when (bc.liked=0 and bc.contact_status=0) then 1 else 0 end) as "unvetted",
concat(format((sum(case when (bc.liked=0 and bc.contact_status=0) then 1 else 0 end)/count(*))*100,0),"%") as "%_unvetted",
sum(case when bc.contact_status>0 then 1 else 0 end) as "contacted",
concat(format((sum(case when bc.contact_status>0 then 1 else 0 end)/count(*))*100,0),"%") as "%_contacted",
-- INTERESTED CANDIDATES
sum(case when cis.status=1 then 1 else 0 end) as "Interested",
concat(format((sum(case when cis.status=1 then 1 else 0 end)/ sum(case when bc.responded=1 then 1 else 0 end))*100,0),"%") as "% Interested",
# OF POSITIONS OPENED
count(distinct p.id) as '# Open positions'
-- CONTRACTS DATA
FROM contracts c
-- CONTRACT DATE ADD ON CORRECTION
    LEFT JOIN (
        select
            cdao.contract_id,
            sum(dao.amount) as amount
        from contract_duration_add_ons as cdao
        left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
        group by
            cdao.contract_id
    ) as addon on addon.contract_id = c.id 
LEFT JOIN contract_trackings ct ON ct.contract_id = c.id -- MATCH BETWEEN contracts and contracts_trackings 
LEFT JOIN customer_companies as cc on c.company_id = cc.company_id -- NEW: MATCH BETWEEN customer_companies and contracts 
LEFT JOIN companies co ON c.company_id = co.id -- MATCH BETWEEN contracts and companies
LEFT JOIN calibers ca ON c.customer_id = ca.id -- MATCH BETWEEN contracts and calibers
-- BATCHES DATA 
LEFT JOIN positions_side_owners as pso on pso.caliber_id = cc.caliber_id -- PROPUESTA 2: JOIN between PSO and customer_companies caliber_id 
LEFT JOIN positions_batches pb ON pso.position_id = pb.position_id -- JOIN between positions_side_owners and positions_batches
LEFT JOIN batch_candidates bc ON bc.batch_id = pb.batch_id         -- JOIN between batch_candidates and positions_batches
LEFT JOIN batches as b on b.id = bc.batch_id
-- INTERESTED CANDIDATES DATA
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pso.position_id -- JOIN entre candidates y positions 
-- POSITIONS DATA
LEFT JOIN positions p ON pso.position_id = p.id AND p.status = 2 -- JOIN between pso and positions and condition for Open Positions
WHERE 1=1
    AND pso.position_id is not NULL
    AND c.status = 1 -- CONTRACT STATUS: ACTIVE 
    AND b.status = 2 -- BATCH STATUS: SENT
    [[AND c.company_id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
    AND b.modified BETWEEN DATE_SUB(curdate(), INTERVAL 60 DAY) AND curdate() -- LAST 60 DAYS
GROUP BY 
    c.id -- GROUP BY CONTRACT  
ORDER BY
    count(distinct p.id) desc;
