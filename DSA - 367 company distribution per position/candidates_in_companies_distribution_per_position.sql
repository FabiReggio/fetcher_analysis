SELECT 
    tmp.company
    , tmp.search_id
    , tmp.search_name
    , tmp.search_status
    , tmp.search_owner
    , tmp.candidate_companny
    , count(distinct unique_id) as total_candidates
    , sum(contacted) as contacted
FROM (
    SELECT  
        c.name AS company
        , p.id AS search_id
        , p.name AS search_name
        , case 
            when p.status in (1,2) then 'OPEN'
            when p.status = 3 then 'CLOSED'
            when p.status = 4 then 'PAUSED'
        end as search_status
        , concat(cal.first_name, ' ',  cal.last_name) AS search_owner
        , uc.name AS candidate_companny
        , bc.caliber_id as candidate_id
        , if(bc.contact_status > 0, 1, 0) as contacted
        , concat(p.id, '-', bc.caliber_id) as unique_id
        , date(b.modified) as sent_date
    FROM calibers cal
        JOIN positions_side_owners pso ON pso.caliber_id = cal.id AND pso.is_owner = 1
        JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
        JOIN companies c ON c.id = cc.company_id
        JOIN positions p ON p.id = pso.position_id
        JOIN positions_batches pb ON pb.position_id = p.id
        JOIN batches b ON b.id = pb.batch_id
        JOIN batch_candidates bc ON bc.batch_id = pb.batch_id
        JOIN caliber_companies ccomp ON ccomp.caliber_id = bc.caliber_id
        JOIN companies uc ON uc.id = ccomp.company_id
    WHERE 1=1
        AND p.type = 0
        AND b.status = 2 -- batch sent
        AND ccomp.start_date is not null
        AND ccomp.start_date != '0000-00-00 00:00:00'
        AND (ccomp.end_date is null OR ccomp.end_date = '0000-00-00 00:00:00')
        [[AND {{company_id}} = c.id]]
        [[AND {{search_id}} = p.id]]
        [[AND lower({{company_name}}) = lower(c.name)]]
        [[AND date(b.modified) >= {{from_date}} ]]
        [[AND date(b.modified) >= {{to_date}} ]]
        AND p.outreach_type = 0 -- campaigns excluded
    ORDER BY c.id, p.id, bc.caliber_id desc
) tmp
WHERE 1=1
[[AND {{status}} = search_status]]
GROUP BY 
    tmp.company
    , tmp.search_id
    , tmp.search_name
    , tmp.search_status
    , tmp.search_owner
    , tmp.candidate_companny
