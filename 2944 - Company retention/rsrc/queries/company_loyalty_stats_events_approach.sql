select
	temp.company_id
	, temp.company_name
	, temp.min_created
	, temp.max_created
	, sum(datediff(
			temp.max_created
			, temp.min_created
	)) as days_in_fetcher
	, sum(datediff(
			temp.max_created
			, temp.min_created
	)) / 365 as years_in_fetcher
from (
	select
		cc.company_id
		, c.name as company_name
		, min(ce.created) as min_created
		, max(ce.created) as max_created
	-- select count(*)
	from candidate_events as ce
	inner join positions_side_owners as pso on
		pso.position_id = ce.position_id
		and pso.is_owner = 1
	left join customer_companies as cc on 
		pso.caliber_id = cc.caliber_id
	left join companies as c on c.id = cc.company_id
	where 1=1
		{filter_flag} and cc.company_id in {filter_values}
	group by
		cc.company_id
) as temp
group by
	temp.company_id
order by
	days_in_fetcher desc