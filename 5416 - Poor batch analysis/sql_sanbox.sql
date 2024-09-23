select
	pb.position_id
	, bc.batch_id
	, bc.caliber_id
	, bct.seeker_id
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
left join positions_batches as pb on pb.batch_id = bc.batch_id -- get position of every batch
left join position_members as team_lead on -- get the position's Team leader
	team_lead.position_id = pb.position_id
	and team_lead.role_id = 2
	/*this won't multiply rows since there are only two positions with more than one Team Leader
	and both are test positions (2270 and 3695)*/
where true
	and b.status = 2 -- sent batches
	and pb.position_id in (18060, 17390, 18342, 18337, 18336, 18335, 18334, 18333, 18332, 18331, 18329)
group by
	bc.batch_id
order by
	pb.position_id
	, b.created desc