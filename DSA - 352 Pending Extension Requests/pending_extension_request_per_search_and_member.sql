SELECT *
FROM (
    SELECT  
        p.id AS search_id
        , p.name AS search_name
        , case 
            when p.status = 1 then 'OPEN'
            when p.status = 2 then 'OPEN'
            when p.status = 3 then 'CLOSED'
            when p.status = 4 then 'PAUSED'
        end as search_status
        , c.name AS company_name
        , c.id AS company_id
        , concat(tl.first_name, ' ', tl.last_name) AS team_lead
        , concat(spec.first_name, ' ', spec.last_name) AS specialist
        , sum(if(ic.status = 0, 1, 0)) AS pending_requests
        , sum(if(ic.status >= 1, 1, 0)) AS resolved_requests
        , max(ic.created) AS last_requested_date
        , max(ic.modified) AS last_resolved_date
    FROM imported_candidates ic
        JOIN positions_side_owners pso ON pso.position_id = ic.position_id AND pso.is_owner = 1
        JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
        JOIN companies c ON c.id = cc.company_id
        JOIN positions p ON p.id = pso.position_id
        LEFT JOIN position_members pmtl ON pmtl.position_id = p.id and pmtl.role_id = 2 -- team lead
        LEFT JOIN calibers tl ON tl.id = pmtl.caliber_id
        LEFT JOIN position_members pms ON pms.position_id = p.id and pms.role_id = 1 -- specialist
        LEFT JOIN calibers spec ON spec.id = pms.caliber_id
    WHERE 1=1
        AND p.type = 0
        AND c.id != -1
        AND p.status != 3 -- filter closed positions
        [[AND {{company_id}} = c.id]]
        [[AND {{search_id}} = p.id]]
        [[AND lower({{company_name}}) = lower(c.name)]]
    GROUP BY
         p.id
        , p.name
        , case 
            when p.status = 1 then 'OPEN'
            when p.status = 2 then 'OPEN'
            when p.status = 3 then 'CLOSED'
            when p.status = 4 then 'PAUSED'
        end
        , c.name
        , c.id
) temp
WHERE 1=1
    AND pending_requests > 0
    [[AND {{status}} = search_status]]
    [[AND lower({{team_lead}}) = lower(team_lead)]]
    [[AND lower({{seeker}}) = lower(specialist)]]
ORDER BY 
    team_lead,
    pending_requests desc,
    last_requested_date asc

