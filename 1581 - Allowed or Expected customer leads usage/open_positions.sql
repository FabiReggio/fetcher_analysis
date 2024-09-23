select
    c.company_id as 'Company ID'
    , companies.name as 'Company name'
    , c.start_date as 'Contract start date'
    , coalesce(date_add(c.end_date, interval addon.amount day), c.end_date) as 'Contract end date'
    /*, case
        when coalesce(date_add(c.end_date, interval dao.amount day), c.end_date) < current_date then 'INACTIVE'
        when c.start_date > current_date then 'INACTIVE'
        else 'ACTIVE'
    end as 'Contract status'*/
    , count(distinct p.id) as 'Open positions'
-- CONTRACTS DATA
from contracts as c
left join contract_trackings as ct on ct.contract_id = c.id
-- CONTRACT DATE ADD ON CORRECTION
left join (
    select
        cdao.contract_id
        , sum(dao.amount) as amount
    from contract_duration_add_ons as cdao
    left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
    group by
        cdao.contract_id
) as addon on addon.contract_id = c.id
-- CUSTOMER AND CUSTOMER COMPANY DATA
left join customer_companies as cc on c.company_id = cc.company_id
left join companies on companies.id = cc.company_id
-- POSITIONS FOR EACH COMPANY
left join positions_side_owners as pso on pso.caliber_id = cc.caliber_id
left join positions as p on p.id = pso.position_id and p.status = 2
where 1=1
    and pso.position_id is not NULL
    and c.status = 1
    [[and c.company_id = {{company_id}}]]
    [[and {{company_name}}]]
group by
    c.company_id
    , c.id
order by
    count(distinct p.id) desc