select
	comp.name as company_name
	, c.*
	, ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as end_date_corrected
	, if(ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) = c.end_date, FALSE, TRUE) as add_on_flag
	, ct.managed_leads_paid
	, ct.managed_leads_used
	, ct.self_served_leads_paid
	, ct.self_served_leads_used
from contracts as c
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
left join contract_trackings as ct on ct.contract_id = c.id
left join companies as comp on comp.id = c.company_id
where 1=1
	{filter_flag} and c.company_id in {filter_values}