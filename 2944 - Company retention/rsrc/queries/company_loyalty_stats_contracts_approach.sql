select
	cc.company_id
	, c.name as company_name
	, count(distinct cont.id) contracts_count
	, sum(cc.is_admin) as admin_count
	, avg(ct.seats_paid) as seats_paid_per_contract
	, avg(ct.managed_leads_paid) as managed_leads_paid_per_contract
	, avg(ct.self_served_leads_paid) as self_served_leads_paid_per_contract
	, avg(cont.price) as avg_contract_price
	, avg(datediff(
		coalesce(date_add(cont.end_date, interval dur_addon.amount day), cont.end_date)
		, cont.start_date
	)) as avg_contract_length_days
	, sum(datediff(
			least(
				coalesce(date_add(cont.end_date, interval dur_addon.amount day), cont.end_date)
				, current_date()
			)
			, cont.start_date
	)) as days_in_fetcher
	, sum(datediff(
			least(
				coalesce(date_add(cont.end_date, interval dur_addon.amount day), cont.end_date)
				, current_date()
			)
			, cont.start_date
	)) / 365 as years_in_fetcher
from customer_companies as cc
inner join contracts as cont on
	cont.company_id = cc.company_id
	and cont.customer_id = cc.caliber_id
left join (
    select
        cdao.contract_id
        , sum(dao.amount) as amount
    from contract_duration_add_ons as cdao
    left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
    group by
        cdao.contract_id
) as dur_addon on dur_addon.contract_id = cont.id
left join contract_trackings as ct on ct.contract_id = cont.id
left join companies as c on c.id = cc.company_id
where 1=1
	and cont.status not in (
		2 -- COMPANY_REVOKED contracts
		, 3 -- INACTIVE contracts
		, 4 -- CANCELED contracts
	)
	{filter_flag} and cc.company_id in {filter_values}
group by
	cc.company_id
order by
	days_in_fetcher desc
	, avg_contract_price