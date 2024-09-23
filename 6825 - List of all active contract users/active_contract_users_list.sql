select 
    co.id as company_id
    , co.name as company_name
    , c.start_date as contract_start_date
    , ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as contract_end_date
    , concat(customer.first_name, ' ', customer.last_name) as customer_name
    , oau.username as email_address
    , pso.position_id
    , case 
            when pso.is_owner=0 then 'Watcher' 
            when pso.is_owner=1 then 'Owner'
      end as is_owner
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
left join oauth_users oau on oau.id = customer.id
left join positions p on p.id = pso.position_id
where 1=1
    and c.status = 1 -- Active Contracts
    and pso.position_id is not null
    and p.created between c.start_date and coalesce(date_add(c.end_date, interval addon.amount day), c.end_date)
    [[and co.id = {{company_id}}]]
    [[and co.name = {{company_name}}]]
    [[and pso.is_owner = {{is_owner}}]]
group by
    co.id
    , pso.position_id -- Grouping by position because there are customers that could be owners and watchers 
    , pso.caliber_id 
order by
    co.created desc;