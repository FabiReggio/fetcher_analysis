select
    cc.company_id
    , c.name as company_name
    , ce.caliber_id as candidate_id
    , ce.position_id
    , ce.batch_id
    , date(b.modified) as batch_sent_date
    , max(case
        when ce.event_id in (
            -- like/dislike events
            201 -- Liked
            , 202 -- Disliked
            -- email events
            , 1 -- Email sent
            , 2 -- Email sent
        ) then 1
        else 0
    end) as vetting_flag
    , date(min(case
                when ce.event_id in (
                    -- like/dislike events
                    201 -- Liked
                    , 202 -- Disliked
                    -- email events
                    , 1 -- Email sent
                    , 2 -- Email sent
                ) then ce.created
                else b.modified
        end)) as vetting_date
from candidate_events as ce
inner join positions_side_owners as pso on
    pso.position_id = ce.position_id
    and pso.is_owner = 1
inner join customer_companies as cc on
    pso.caliber_id = cc.caliber_id
left join companies as c on c.id = cc.company_id
left join batches as b on b.id = ce.batch_id
where 1=1
    and b.status = 2
group by
    ce.caliber_id
    , ce.position_id
    , ce.batch_id