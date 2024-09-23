select
    c.company_id
    , co.name as company_name
    , c.start_date
    , ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as end_date
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
left join companies co on c.company_id = co.id
where 1=1
    and c.company_id not in ( -- non active companies
        select c.company_id
        from contracts c
        -- CONTRACT STATUS: Active
        where c.status = 1
    )
    and c.status = 0 -- Contract Status: Expired
    {filter_flag} and c.company_id in {filter_values}
    and year(ifnull(date_add(c.end_date, interval addon.amount day), c.end_date)) = {churn_year}
group by c.company_id