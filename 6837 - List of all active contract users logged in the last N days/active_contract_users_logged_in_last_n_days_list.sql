select 
    co.id as company_id
    , co.name as company_name
    , c.start_date as contract_start_date
    , ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as contract_end_date
    , concat(customer.first_name, ' ', customer.last_name) as customer_name
    , users.username as email_address
    , users.last_login_datetime
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
left join oauth_users users on users.id = customer.id
left join positions p on p.id = pso.position_id
where 1=1
    and c.status = 1 -- Active Contracts
    and pso.position_id is not null
    and p.created between c.start_date and coalesce(date_add(c.end_date, interval addon.amount day), c.end_date)
    and users.created not between date_sub(curdate(), interval 45 DAY) and curdate() -- Excluding users created the last 45 days 
    and users.last_login_datetime between date_sub(curdate(), interval {{logged_in_last_n_days}} DAY) and curdate() -- Users logged in into the platform the last 30 days
    [[and co.id = {{company_id}}]]
    [[and co.name = {{company_name}}]]
group by
    co.id
    , pso.caliber_id 
order by
    co.created desc;
