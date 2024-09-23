select
	pb.position_id
	, bc.batch_id
	, bc.caliber_id
	, team_lead.caliber_id as team_lead_id
	, concat(tl_info.first_name, ' ', tl_info.last_name) as team_lead_name
	, bct.seeker_id as specialist_id
	, concat(seeker_info.first_name, ' ', seeker_info.last_name) as specialist_name
	, b.created as batch_date
	, count(distinct bc.caliber_id) as candidate_count
	, sum(if(bc.liked = 2, 1, 0)) as dislike_count
	, sum(if(bc.liked = 2, 1, 0)) / count(distinct bc.caliber_id) as dislike_rate
-- select *
from batch_candidates as bc -- candidate for every batch
left join batches as b on b.id = bc.batch_id
left join batch_candidates_tracking as bct on -- seeker for every candidate-batch
	bct.batch_id = bc.batch_id
	and bct.candidate_id = bc.caliber_id
inner join positions_batches as pb on pb.batch_id = bc.batch_id -- get position of every batch
left join position_members as team_lead on -- get the position's Team leader
	team_lead.position_id = pb.position_id
	and team_lead.role_id = 2
	/*this won't multiply rows since there are only two positions with more than one Team Leader
	and both are test positions (2270 and 3695)*/
left join calibers as tl_info on tl_info.id = team_lead.caliber_id
left join calibers as seeker_info on seeker_info.id = bct.seeker_id
where true
	and b.status = 2 -- sent batches
	and ( -- date filters to get batches on the last month
		year(b.created) = year(date_add(curdate(), interval -1 month))
		and month(b.created) = month(date_add(curdate(), interval -1 month))
		)
	-- and pb.position_id in (12580, 12581, 12585, 12587, 12590, 12591, 12597, 12598, 12599, 12600, 12601, 12602, 12604, 12610, 12615, 12619, 12621, 12623, 12629, 12633)
group by
	bc.batch_id
order by
	pb.position_id
	, b.created desc