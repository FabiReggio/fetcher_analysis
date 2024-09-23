select
	temp.seeker_id as 'Seeker ID'
	, temp.seekers_name as 'Seekers name'
	, temp.team_leader_id as 'Team Leader ID'
	, temp.team_leader as 'Team leader'
	, temp.position_id as 'Position ID'
	, temp.batch_id as 'Batch ID'
	, batch_type as "Batch Type"
	, temp.batch_sent_date as 'Batch sent date'
	, year(temp.batch_sent_date) as 'Year'
	, monthname(temp.batch_sent_date) as 'Month'
	, week(temp.batch_sent_date) as 'Week'
	, temp.leads_sent as 'Leads sent'
	, temp.unvetted_count as 'Unvetted count'
	, (temp.leads_sent - temp.unvetted_count) as 'Vetted leads'
	, temp.scheduled_count as 'Scheduled count'
	, temp.contacted_count as 'Contacted count'
	, greatest(temp.scheduled_count, temp.contacted_count) as 'Final contacted'
	, temp.likes_count as 'Likes count'
	, temp.dislikes_count as 'Dislikes count'
	, (temp.contacted_count / temp.leads_sent) as 'Contacted rate'
	, (temp.likes_count / temp.leads_sent) as 'Likes rate'
	, (temp.dislikes_count / temp.leads_sent) as 'Dislikes rate'
from (
	select
		pm.caliber_id as seeker_id
		, concat(seekers.first_name, ' ', seekers.last_name) as seekers_name
		, tl_info.id as team_leader_id
		, concat(tl_info.first_name, ' ', tl_info.last_name) as team_leader
		, pb.position_id as position_id
		, bc.batch_id as batch_id
		, case 
            	  when batches.type=1 
                    then 'Fetcher Search'
                  when batches.type=2 and batches.name="Copied Profiles" 
                    then 'Fetcher Search' 
                  when batches.type=2 and batches.name="Campaign Batch" 
                    then 'Campaign' 
                  when batches.type=3 
                    then 'Extension'
                  end as batch_type
		, date(batches.modified) as batch_sent_date
		, count(distinct bc.caliber_id) as leads_sent
		, sum(
			case
				when (
					bc.contact_status = 0
					and bc.status <= 2
					and bc.liked = 0
				) then 1
				else 0
			end
		) as unvetted_count
		, sum(
			case
				when bc.status = 7 then 1
				else 0
			end
		) as scheduled_count
		, sum(
			case
				when bc.contact_status != 0 then 1
				else 0
			end
		) as contacted_count
		, sum(
			case
				when bc.liked = 1 then 1
				else 0
			end
		) as likes_count
		, sum(
			case
				when bc.liked = 2 then 1
				else 0
			end
		) as dislikes_count
	from batch_candidates as bc -- which seeker added which candidate to a certain batch
	left join positions_batches as pb on pb.batch_id = bc.batch_id
	left join batches on batches.id = bc.batch_id
	-- INFO ABOUT THE FETCHER TEAM
	left join position_members as pm on
		pb.position_id = pm.position_id
		and pm.role_id = 1 -- Seeker role
	left join calibers as seekers on seekers.id = pm.caliber_id -- info about the seeker
	-- INFO ABOUT THE TEAM LEADER
	left join position_members as tl on -- info about who the Team leader is
		tl.position_id = pb.position_id
		and tl.role_id = 2 -- Team Leader role
	left join calibers as tl_info on tl_info.id = tl.caliber_id -- data about the Team leader
	where 1=1
		and batches.status = 2
		[[and pm.caliber_id in ({{seeker_id}})]]   
		[[and concat(seekers.first_name, ' ', seekers.last_name) regexp {{seeker_name}}]]
		[[and tl_info.id in ({{team_leader_id}})]]  
		[[and concat(tl_info.first_name, ' ', tl_info.last_name) regexp {{team_leader}}]]
		[[and pb.position_id = {{position_id}}]]
		[[and {{date_range}}]] -- start date
	group by
		bc.batch_id
		, pb.position_id
		, pm.caliber_id
		, tl_info.id
) as temp
