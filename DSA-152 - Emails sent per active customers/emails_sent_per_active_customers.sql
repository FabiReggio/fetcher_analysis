select 
    temp.company_id
    , temp.company_name
    , sum(temp.emailed) as emailed
    , sum(temp.positions) as active_positions
from (
    select 
        co.id as company_id
        , co.name as company_name
        , co.created as company_created
        , (select 
                count(distinct ce.caliber_id) 
            from candidate_events ce 
            where 1=1 
                and ce.position_id=p.id 
                and ce.event_id in (1,2) -- Emailed
                and date(ce.created) between c.start_date and coalesce(date_add(c.end_date, interval addon.amount day), c.end_date)
                [[and date(ce.created) between {{start_date}} and {{end_date}}]]
            ) as emailed
        , count(p.id) as positions
    from contracts c
    -- CONTRACT END DATE ADD ON CORRECTION
    left join (
        select
            cdao.contract_id,
            sum(dao.amount) as amount
        from contract_duration_add_ons as cdao
        left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
        group by
            cdao.contract_id
    ) as addon on addon.contract_id = c.id 
    left join customer_companies as cc on cc.company_id = c.company_id 
    left join companies co on co.id = c.company_id 
    left join positions_side_owners as pso on pso.caliber_id = cc.caliber_id 
    left join calibers as customer on pso.caliber_id = customer.id 
    left join positions p on p.id = pso.position_id
    where 1=1
        and c.status = 1 -- Active Contracts
        and pso.position_id is not null
        and pso.is_owner = 1 
        and p.status in (1, 2) -- New and Open Positions 
        and p.created between c.start_date and coalesce(date_add(c.end_date, interval addon.amount day), c.end_date)
        [[and co.id = {{company_id}}]]
        [[and co.name = {{company_name}}]]
    group by
        co.id
        , pso.position_id
        , pso.caliber_id 
    ) as temp
group by 
    temp.company_id
order by 
    temp.company_created desc;