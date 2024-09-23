select
	temp.company_id as 'Company ID'
	, temp.company_name as 'Company name'
	, temp.contract_id as 'Contract ID'
	, temp.start_date as 'Contract start date'
	, temp.end_date as 'Contract end date'
	, sum(temp.likes) as 'Likes'
	, sum(temp.likes) / sum(temp.total_leads) as 'Likes rate'
	, sum(temp.dislikes) as 'Dislikes'
	, sum(temp.dislikes) / sum(temp.total_leads) as 'Dislikes rate'
	, sum(temp.unvetted) as 'Unvetted'
	, sum(temp.unvetted) / sum(temp.total_leads) as 'Unvetted rate'
	, sum(temp.emailed) as 'Emailed'
	, sum(temp.emailed) / sum(temp.total_leads) as 'Contacted rate'
	, sum(temp.responded) as 'Responded'
	, sum(temp.responded) / sum(temp.emailed) as 'Responded rate'
from (
	select
		cc.company_id
		, companies.name as company_name
		, contracts.id as contract_id
		, contracts.start_date
		, coalesce(date_add(contracts.end_date, interval dur_addon.amount day), contracts.end_date) as end_date
		, pso.position_id as position_id
		, count(distinct batches.id) as batches_sent
		, case batches.type
			when 1 then count(distinct bc.caliber_id)
			else 0
		end as fetcher_leads
		, case batches.type
			when 2 then count(distinct bc.caliber_id)
			else 0
		end as copied_leads
		, case batches.type
			when 3 then count(distinct bc.caliber_id)
			else 0
		end as extension_leads
		, count(distinct bc.caliber_id) as total_leads
		, sum(
			case
				when (
					bc.contact_status = 0 -- NON-CONTACTED
					and bc.status <= 2 -- NEW or VIEWED candidate
					and bc.liked = 0 -- NEUTRAL STATUS (nor like neither dislike)
				) then 1
				else 0
			end
		) as unvetted
		, sum(
			case
				when bc.liked = 1 then 1
				else 0
			end
		) as likes
		, sum(
			case
				when bc.liked = 2 then 1
				else 0
			end
		) as dislikes
		, sum(
			case
				when bc.contact_status >= 1 then 1
				else 0
			end
		) as emailed
		, sum(bc.responded) as responded
	from customer_companies as cc
	left join contracts as contracts on contracts.company_id = cc.company_id
	-- CONTRACT DURATION ADD ONS
	left join (
		select
			cdao.contract_id
			, sum(dao.amount) as amount
			, sum(cdao.price) as price_addon
		from contract_duration_add_ons as cdao
		left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
		group by
			cdao.contract_id
	) as dur_addon on dur_addon.contract_id = contracts.id
	left join positions_side_owners as pso on
		pso.caliber_id = cc.caliber_id
		and pso.is_owner = 1
	left join positions_batches as pb on pb.position_id = pso.position_id
	left join batch_candidates as bc on bc.batch_id = pb.batch_id
	left join batches on batches.id = pb.batch_id
	left join companies on companies.id = cc.company_id
	where 1=1
		and pso.position_id is not null
		and batches.status = 2 -- SENT batches
		and contracts.status = 1 -- ACTIVE contracts
		[[and {{contract_start}}]]
		[[and {{contract_end}}]]
	group by
		cc.company_id
		, pso.position_id
		, batches.id
) as temp
group by
	temp.company_id
order by
    sum(temp.total_leads) desc