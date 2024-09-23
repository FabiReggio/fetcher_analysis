select
    agg.company_id as 'Company ID'
    , agg.company_name as 'Company name'
    , agg.year_sent as 'Year sent'
    , agg.week_sent as 'Week sent'
    , sum(fetcher_leads) as 'Fetcher leads'
    , sum(extension_leads) as 'Extension leads'
from (
    SELECT
        p.id AS position_id
        , p.name AS position
        , companies.id as company_id
        , companies.name AS company_name
        , b.id as batch_id
        , b.name as batch_name
        , b.modified
        , year(b.modified) as year_sent
        , week(b.modified) as week_sent
        , case
            when lower(b.name) not like '%extension%' then count(distinct bc.caliber_id)
            else 0
        end as fetcher_leads
        , case
            when lower(b.name) like '%extension%' then count(distinct bc.caliber_id)
            else 0
        end as extension_leads
    FROM positions p
    left JOIN positions_batches pb ON pb.position_id = p.id
    left JOIN positions_side_owners pso ON pso.is_owner = 1
        AND pso.position_id = p.id
    left JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
    left JOIN companies ON companies.id = cc.company_id
    left JOIN batches b ON b.id = pb.batch_id
    left join batch_candidates as bc on bc.batch_id = b.id
    WHERE 1=1
        AND b.status = 2 -- SENT
        AND b.type in (1, 3) -- CANDIDATES and SELF SOURCED
        and companies.id > 0
        [[and {{company_name}}]]
        [[and companies.id = {{company_id}}]]
        [[and year(b.modified) = {{year}}]]
        [[and week(b.modified) = {{week}}]]
    GROUP by
        p.id
        , b.id
) as agg
group by
    agg.company_id
    , agg.year_sent
    , agg.week_sent
order by
    sum(fetcher_leads) desc