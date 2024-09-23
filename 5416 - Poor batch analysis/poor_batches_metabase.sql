select
	companies.name as 'Company name'
	, pb.position_id as 'Position ID'
	, bc.batch_id as 'Batch ID'
	, team_lead.caliber_id as 'Team Lead ID'
	, concat(tl_info.first_name, ' ', tl_info.last_name) as 'Team Lead name'
	, bct.seeker_id as 'Specialist ID'
	, concat(seeker_info.first_name, ' ', seeker_info.last_name) as 'Specialist name'
	, sum(if(bc.liked = 2, 1, 0)) / count(distinct bc.caliber_id) as 'Disliked Rate'
	, date_format(date(pb.created),"%m/%d/%y") as 'Day'
from batch_candidates as bc -- candidate for every batch
left join batches as b on b.id = bc.batch_id
left join batch_candidates_tracking as bct on -- seeker for every candidate-batch
	bct.batch_id = bc.batch_id
	and bct.candidate_id = bc.caliber_id
left join positions_batches as pb on pb.batch_id = bc.batch_id -- get position of every batch
left join positions as p on p.id = pb.position_id
left join companies on p.company_id = companies.id
left join position_members as team_lead on -- get the position's Team leader
	team_lead.position_id = pb.position_id
	and team_lead.role_id = 2
	/*this won't multiply rows since there are only two positions with more than one Team Leader
	and both are test positions (2270 and 3695)*/
left join calibers as tl_info on tl_info.id = team_lead.caliber_id
left join calibers as seeker_info on seeker_info.id = bct.seeker_id
where true
	[[and {{company_name}}]]
	[[and {{day}}]]
group by
	bc.batch_id
having `Disliked Rate` > 0.5