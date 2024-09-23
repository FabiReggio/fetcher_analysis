select
    agg.position_id as pid
    , agg.position
    , agg.company
    , agg.status
    , sum(agg.fetcher_leads) as fetcher_leads
    , sum(agg.extension_leads) as extension_leads
from (
    SELECT
        p.id AS position_id
        , p.name AS position
        , c.name AS company
        , b.id as batch_id
        , b.name as batch_name
        , b.modified
        , CASE
            WHEN p.status = 1 THEN 'New'
            WHEN p.status = 2 THEN 'Open'
            WHEN p.status = 3 THEN 'Closed'
            WHEN p.status = 4 THEN 'On hold'
        END AS status
        , count(distinct
            case
                when b.type = 1 then bc.caliber_id
                else null
            end
        ) as fetcher_leads
        , count(distinct
            case
                when b.type = 3 then bc.caliber_id
                else null
            end
        ) as extension_leads
        -- , count(distinct bc.caliber_id) as leads_on_batch
    FROM positions p
    left JOIN positions_batches pb ON pb.position_id = p.id
    left JOIN positions_side_owners pso ON pso.is_owner = 1
        AND pso.position_id = p.id
    inner JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
    left JOIN companies c ON c.id = cc.company_id
    left JOIN batches b ON b.id = pb.batch_id
    left join batch_candidates as bc on bc.batch_id = b.id
    WHERE 1=1
        AND b.status = 2 -- SENT
        AND b.type in (1, 3) -- CANDIDATES and SELF SOURCED
        [[and if(
            b.type = 1
            , date(b.modified)
            , date(bc.created)
            ) >= {{start_date}}]]
        [[and if(
            b.type = 1
            , date(b.modified)
            , date(bc.created)
            ) <= {{end_date}}]]
    GROUP by
        p.id
        , b.id
) as agg
group by
    agg.position_id
    , agg.position
    , agg.company
    , agg.status