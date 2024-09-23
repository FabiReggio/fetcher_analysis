select
	temp.company_id as 'Company ID'
	, temp.company_name as 'Company name'
	, temp.position_id as 'Position ID'
	, temp.position_name as 'Position name'
	, count(distinct temp.batch_id) as 'Batches sent'
	, sum(temp.unvetted_batch) as 'Unvetted batches'
	, (sum(temp.unvetted_batch) / count(distinct temp.batch_id)) as '%Unvetted batches'
from (
	select
		cc.company_id
		, companies.name as company_name
		, pso.position_id as position_id
		, positions.name as position_name
		, bc.batch_id
		, count(distinct bc.caliber_id) as candidate_count
		, case -- unvetted_rate >= 0.5 then unvetted batch else non unvetted batch
			when (
				sum(case
					when (
						bc.contact_status = 0
						and bc.status <= 2
						and bc.liked = 0
					) then 1
					else 0
				end) -- number of unvetted candidates
				/
				count(distinct bc.caliber_id) -- total number of candidates
			) >= 0.5 then true
			else false
		end as unvetted_batch
	from customer_companies as cc
	left join positions_side_owners as pso on
		pso.caliber_id = cc.caliber_id
		and pso.is_owner = 1
	left join positions_batches as pb on pb.position_id = pso.position_id
	left join batch_candidates as bc on bc.batch_id = pb.batch_id
	left join batches on batches.id = bc.batch_id
	left join positions on positions.id = pso.position_id
	left join companies on companies.id = cc.company_id
	where 1=1
		and pso.position_id is not null
		and batches.status = 2
		[[and {{company_id}}]]
		[[and {{position_id}}]]
		[[and {{batch_date}}]]
	group by
		cc.company_id
		, pso.position_id
		, bc.batch_id
) as temp
group by
	temp.position_id
having
	sum(temp.unvetted_batch) >= {{unvetted_threshold}}