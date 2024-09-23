select
	rank_table.company_id
	, rank_table.position_id
	, case pos_stats.position_status
		when 1 then 'New'
		when 2 then 'Open'
		when 3 then 'Closed'
		when 4 then 'Hold'
	end as position_status
	, pos_stats.batch_id
	, pos_stats.position_date
	, datediff(rank_table.candidate_date, pos_stats.position_date) as days_until_{{Nth_candidate}}th_candidate
	, @position_life := case
		-- HOLD and CLOSED positions
		when pos_stats.position_status in (3, 4) then datediff(pos_stats.last_batch_date, pos_stats.position_date)
		-- NEW and OPEN positions
		when pos_stats.position_status in (1, 2) then datediff(current_date(), pos_stats.position_date)
	end as position_life
	, (pos_stats.candidate_count / (@position_life / 7)) candidates_per_week
	, pos_stats.interested_count
	, pos_hires.hires_count
from ( -- Getting the order on which candidates were delivered
	select
		data_table.*
		, @order_rank := IF(
	        @current_position = data_table.position_id
	        , @order_rank + 1
	        , 1
	    ) AS candidate_order
	    , @current_position := data_table.position_id as current_position
	from (
		select
			pb.position_id
			, positions.company_id
			, bc.caliber_id as candidate_id
			, bc.created as candidate_date
		from positions_batches as pb
		left join batch_candidates as bc on bc.batch_id = pb.batch_id
		left join positions on positions.id = pb.position_id
		where true
			[[and {{company_id}}]]
			[[and {{position_id}}]]
	) as data_table
) as rank_table
left join ( -- Getting several stats for each position
	select
		pb.position_id
		, p.status as position_status
		, p.created as position_date
		, pb.batch_id
		, max(pb.created) as last_batch_date
		, count(distinct bc.caliber_id) as candidate_count
		, sum(cis.status) as interested_count
	from positions_batches as pb
	left join batch_candidates as bc on bc.batch_id = pb.batch_id
	left join positions as p on p.id = pb.position_id
	left join candidate_interested_status as cis on
		cis.position_id = pb.position_id
		and cis.candidate_id = bc.caliber_id
	group by
		pb.position_id
) as pos_stats on pos_stats.position_id = rank_table.position_id
left join ( -- Getting hires count for each position
	select
		ce.position_id
		, (
			sum(if(ce.event_id = 405, 1, 0)) -- hires count
			-
			sum(if(ce.event_id = 412, 1, 0)) -- undo hires count
		) as hires_count
	from candidate_events as ce
	where true
		and ce.event_id in (
			405 -- Hire
			, 412 -- Undo hire
			)
	group by
		ce.position_id
) as pos_hires on pos_hires.position_id = rank_table.position_id
where 1=1
	and rank_table.candidate_order = {{Nth_candidate}}
	and year(pos_stats.position_date) >= 2020