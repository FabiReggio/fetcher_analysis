select
	temp.company_id
	, temp.contract_id
	, temp.first_contract_start_date
	, temp.first_pos_date
	, datediff(
		temp.first_pos_date
		, temp.first_contract_start_date
	) as days_until_first_pos
	, temp.first_batch_sent_date
	, datediff(
		temp.first_batch_sent_date
		, temp.first_contract_start_date
	) as days_until_first_batch_sent
	, temp.first_like_date
	, datediff(
		temp.first_like_date
		, temp.first_contract_start_date
	) as days_until_first_like
	, temp.first_email_sent_date
	, datediff(
		temp.first_email_sent_date
		, temp.first_contract_start_date
	) as days_until_first_email_sent
	, temp.first_interested_date
	, datediff(
		temp.first_interested_date
		, temp.first_contract_start_date
	) as days_until_first_interested
from (
	select
		cc.company_id
		, cont.id as contract_id
		, cont.status as contract_status
		, p.id as position_id
		, ce.batch_id
		, date(min(cont.start_date)) as first_contract_start_date
		, date(min(p.created)) as first_pos_date
		, date(min(b.modified)) as first_batch_sent_date
		, date(min(
			case
				when ce.event_id = 201 then ce.created
				else null
			end
		)) as first_like_date
		, date(min(
			case
				when ce.event_id in (1, 2) then ce.created
				else null
			end
		)) as first_email_sent_date
		, date(min(
			case
				when ce.event_id = 408 then ce.created
				else null
			end
		)) as first_interested_date
	from customer_companies as cc
	inner join (
		select
			contracts.id
			, contracts.company_id
			, contracts.customer_id
			, contracts.status
			, contracts.start_date
			, coalesce(
				date_add(contracts.end_date, interval dur_addon.amount day)
				, contracts.end_date
			) as end_date
		from contracts
		left join (
		    select
		        cdao.contract_id
		        , sum(dao.amount) as amount
		    from contract_duration_add_ons as cdao
		    left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
		    group by
		        cdao.contract_id
		) as dur_addon on dur_addon.contract_id = contracts.id
	) as cont on cont.company_id = cc.company_id
	left join positions_side_owners as pso on
		pso.caliber_id = cc.caliber_id
		and pso.is_owner = 1
		and pso.created between cont.start_date and cont.end_date
	left join positions as p on p.id = pso.position_id
	left join candidate_events as ce on ce.position_id = pso.position_id
	left join batches as b on b.id = ce.batch_id
	where 1=1
		and p.created >= cont.start_date
		and cont.status in (
			0 -- EXPIRED
			, 1 -- ACTIVE
		)
		and ce.event_id in (
			-- like/dislike events
			201 -- Liked
			-- interest events
			, 408 -- Interested
			-- email events
			, 1 -- Email sent
			, 2 -- Email sent
		)
		and b.status = 2
		{filter_flag} and cc.company_id in {filter_values}
	group by
		cc.company_id
) as temp
group by
	temp.company_id