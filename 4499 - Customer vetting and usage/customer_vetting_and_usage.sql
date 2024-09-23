select
	temp.company_id
	, temp.company_name
	, temp.position_id
	, temp.position_name
	, temp.position_status
	, temp.position_mode
	, temp.owner_id
	, temp.owner
	, sum(temp.batches_sent) as batches_sent
	, sum(temp.total_leads) as total_leads
	, sum(temp.fetcher_leads) as fetcher_leads  
	, sum(temp.fetcher_leads) / sum(temp.total_leads) as fetcher_leads_rate
	, sum(temp.copied_leads) as copied_leads
	, sum(temp.copied_leads) / sum(temp.total_leads) as copied_leads_rate
	, sum(temp.extension_leads) as extension_leads
	, sum(temp.extension_leads) / sum(temp.total_leads) as extension_leads_rate
	, sum(temp.likes) as likes
	, sum(temp.likes) / sum(temp.total_leads) as likes_rate
	, sum(temp.dislikes) as dislikes
	, sum(temp.dislikes) / sum(temp.total_leads) as dislikes_rate
	, sum(temp.unvetted) as unvetted
	, sum(temp.unvetted) / sum(temp.total_leads) as unvetted_rate
	, sum(temp.scheduled) as scheduled
	, sum(temp.scheduled) / sum(temp.total_leads) as scheduled_rate
	, sum(temp.contacted) as emailed
	, sum(temp.contacted) / sum(temp.total_leads) as emailed_rate
	, coalesce(open_emails, 0) as open_emails
	, coalesce(open_emails / sum(temp.contacted), 0) as open_rate
	, sum(temp.responded) as responded
	, sum(temp.responded)/ sum(temp.contacted) as responded_rate
	, sum(temp.interested) as interested
	, sum(temp.interested) / sum(temp.responded) as interested_rate
	, coalesce(event_counters.screened, 0) as screened
	, coalesce(event_counters.screened, 0) / sum(temp.total_leads) as screened_rate
	, coalesce(event_counters.interviewed, 0) as interviewed
	, coalesce(event_counters.interviewed, 0) / sum(temp.total_leads) as interviewed_rate
	, coalesce(event_counters.hires, 0) as hired
	, coalesce(event_counters.hires, 0) / sum(temp.total_leads) as hired_rate
from (
	select
		cc.company_id
		, companies.name as company_name
		, pso.position_id as position_id
		, positions.name as position_name
		, case
				when positions.operation_mode = 0 then 'fetcher_mode'
				else 'self_source_mode'
		end
	    as position_mode
		, case
			when positions.status = 1 then 'New'
			when positions.status = 2 then 'Open'
			when positions.status = 3 then 'Closed'
			when positions.status = 4 then 'Hold'
			else 'CHECK FOR ERROR HERE'
		end as position_status
		, p_owner.id as owner_id
		, concat(p_owner.first_name, ' ', p_owner.last_name) as owner
		, count(distinct batches.id) as batches_sent
		, case
			when batches.type = 1 then count(distinct batch_candidates.caliber_id)
			else 0
		end as fetcher_leads
		, case
			when batches.type = 2 then count(distinct batch_candidates.caliber_id)
			else 0
		end as copied_leads
		, case
			when batches.type = 3 then count(distinct batch_candidates.caliber_id)
			else 0
		end as extension_leads
		, count(distinct batch_candidates.caliber_id) as total_leads
		, sum(batch_candidates.responded) as responded
		, sum(
			case when batch_candidates.contact_status >= 1 then 1 
				else 0 
			end
		) as contacted
		, sum(
			case
				when batch_candidates.liked = 1 then 1
				else 0
			end
		) as likes
		, sum(
			case
				when batch_candidates.liked = 2 then 1
				else 0
			end
		) as dislikes
		, sum(
			case
				when (
					batch_candidates.contact_status = 0
					and batch_candidates.status <= 2
					and batch_candidates.liked = 0
				) then 1
				else 0
			end
		) as unvetted
		, sum(
			case
				when batch_candidates.status = 7 then 1
				else 0
			end
		) as scheduled
		, sum(
			case
				when cis.status = 1 then 1
				else 0
			end
		) as interested
	from customer_companies as cc
	left join positions_side_owners as pso on
		pso.caliber_id = cc.caliber_id
		and pso.is_owner = 1
	left join positions_batches as pb on pb.position_id = pso.position_id
	left join batch_candidates on batch_candidates.batch_id = pb.batch_id
	left join batches on batches.id = pb.batch_id
	left join positions on positions.id = pso.position_id
	left join calibers as p_owner on p_owner.id = pso.caliber_id
	left join companies on companies.id = cc.company_id
	left join candidate_interested_status cis ON cis.candidate_id = batch_candidates.caliber_id AND cis.position_id = pso.position_id
	where 1=1
		and pso.position_id is not null
		and batches.status = 2
		[[and companies.id = {{company_id}}]]
		[[and {{company_name}}]]
		[[and {{position_id}}]]
		[[and {{lead_creation_date}}]]
	group by
		cc.company_id
		, pso.position_id
		, batches.id
		, position_mode
) as temp
left join (
    select tp.position_id as pid
           , count(distinct tp.caliber_id) as open_emails
    from tracking_pixels tp
    join positions p on tp.position_id = p.id
    join positions_side_owners pso on pso.position_id = p.id and pso.is_owner = 1
    join customer_companies cc on cc.caliber_id = pso.caliber_id
    /* Important join: sometimes we have tracking pixels from removed candidates, and that generates open rate > 100% by joining with BC we omit those cases */
    join batch_candidates bc on bc.caliber_id = tp.caliber_id and bc.batch_id = tp.batch_id
    where 
        tp.status = 1 
        and bc.contact_status > 0
		[[and cc.company_id = {{company_id}}]]
    group by tp.position_id
) as pixels on pixels.pid = temp.position_id
left join (
	select
		position_id
		, sum(if(event_id = 405, 1, 0)) - sum(if(event_id = 412, 1, 0))  as hires
		, sum(if(event_id = 403, 1, 0)) - sum(if(event_id = 413, 1, 0)) as interviewed
		, sum(if(event_id = 402, 1, 0)) -  sum(if(event_id = 414, 1, 0)) as screened
	from candidate_events
	where 1=1
		and event_id in (
			403 -- interviewed
			, 413 -- undo interviewed
			, 405 -- hired
			, 412 -- undo hired
			, 402 -- screeneed
			, 414 -- undo screened
		)
	group by position_id 
) as event_counters on event_counters.position_id = temp.position_id
group by
	temp.company_id
	, temp.position_id
order by
    sum(temp.total_leads) desc