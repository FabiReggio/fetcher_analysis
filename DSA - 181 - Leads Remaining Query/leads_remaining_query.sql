SELECT 
    co.id as "Company Id"
    , co.name as "Company Name"
    , case 
        when c.status = 0 then "Expired"
        when c.status = 1 then "Active"
        when c.status = 2 then "Company Revoked"
        when c.status = 3 then "Contract Inactive"
        when c.status = 4 then "Canceled"
        else null
    end as "Contract Status"
    , ct.managed_leads_paid as "Fetcher Leads"
    , ct.managed_leads_used as "Fetcher Leads Used"
    , (ct.managed_leads_paid - ct.managed_leads_used) as "Fetcher Leads Remaining"
    , ct.self_served_leads_paid as "Extension Leads"
    , ct.self_served_leads_used as "Extension Leads Used"
    , (ct.self_served_leads_paid - ct.self_served_leads_used) as "Extension Leads Remaining"
     -- SPEED
FROM contract_trackings ct
LEFT JOIN contracts c ON c.id = ct.contract_id 
LEFT JOIN companies co ON co.id = c.company_id
WHERE 1=1
    AND co.id not in (
        594088  -- Fetcher
        , 1511629 -- Fetcher Test
        , 2726125 -- Fetcher Demo
        , 3282516 -- Fetcher Nylas
        , 3301100 -- outlook v1 nylas
        )
    [[AND co.id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
ORDER BY
    c.created desc
;