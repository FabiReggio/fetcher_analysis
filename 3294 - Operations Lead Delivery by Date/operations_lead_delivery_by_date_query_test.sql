select
    temp.company_id as 'Company ID'
    , temp.company_name as 'Company Name'
    -- , temp.customer_id as 'Customer ID'
    , customer_name as 'Customer Name'
	, temp.search_manager_id as 'Search Manager ID'
	, temp.search_manager as 'Search Manager'
	, temp.team_leader_id as 'Team Leader ID'
	, temp.team_leader as 'Team leader'
	, temp.seeker_id as 'Seeker ID'
	, temp.seeker_name as 'Seeker Name'
	, temp.position_id as 'Position ID'
	, temp.batch_id as 'Batch ID'
	, temp.batch_sent_date as 'Batch sent date'
	, year(temp.batch_sent_date) as 'Year'
	, monthname(temp.batch_sent_date) as 'Month'
	, week(temp.batch_sent_date) as 'Week'
	, (temp.leads_sent - temp.extension_leads) as 'Leads sent' -- Total leads sent without extensions
	, temp.fetcher_leads as 'Fetcher Leads'
	, temp.extension_leads as 'Extension Leads'
	, temp.copied_leads as 'Copied Leads'
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
	    co.id as company_id
	    , co.name as company_name
	    , customers.id as customer_id 
	    , concat(customers.first_name, ' ', customers.last_name) as customer_name
	    , bct.seeker_id as seeker_id
    	, concat(seeker.first_name, ' ', seeker.last_name) as seeker_name
		, tl_info.id as team_leader_id
		, concat(tl_info.first_name, ' ', tl_info.last_name) as team_leader
		, sm_info.id as search_manager_id
		, concat(sm_info.first_name, ' ', sm_info.last_name) as search_manager
		, pb.position_id as position_id
		, bc.batch_id as batch_id
		, date(batches.modified) as batch_sent_date
		, count(distinct bc.caliber_id) as leads_sent
		, case
			when batches.type = 1 then count(distinct bc.caliber_id)
			else 0
		end as fetcher_leads
		, case
			when batches.type = 2 then count(distinct bc.caliber_id)
			else 0
		end as copied_leads
		, case
			when batches.type = 3 then count(distinct bc.caliber_id)
			else 0
		end as extension_leads
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
		
	from batch_candidates as bc 
	left join positions_batches as pb on pb.batch_id = bc.batch_id
	left join batches on batches.id = bc.batch_id
	left join positions p on pb.position_id = p.id 
	left join companies co on co.id = p.company_id 
	left join customer_companies cc on cc.company_id = co.id
	left join calibers as customers on customers.id = cc.caliber_id -- info about the customers
	left join positions_side_owners pso on pso.caliber_id = cc.caliber_id and pso.position_id = pb.position_id
	
	-- INFO ABOUT THE TEAM LEADER
	left join position_members as tl on -- info about who the Team leader is
		tl.position_id = pb.position_id
		and tl.role_id = 2 -- Team Leader role
	left join calibers as tl_info on tl_info.id = tl.caliber_id -- data about the Team leader

    -- INFO ABOUT THE SEARCH MANAGER
	left join position_members as sm on -- info about the Search Manager
		sm.position_id = pb.position_id
		and sm.role_id = 3 -- Search Manager role
	left join calibers as sm_info on sm_info.id = sm.caliber_id -- data about the Search Manager
	
    -- INFO ABOUT WHICH SEEKER ADDED A CANDIDATE TO A CERTAIN BATCH
	left join batch_candidates_tracking bct
	     on bct.batch_id = bc.batch_id        -- Batch
	     and bct.candidate_id = bc.caliber_id -- Candidate
	left join calibers as seeker on seeker.id = bct.seeker_id
	
	where 1=1

		and batches.status = 2 -- Batch status sent
		and pso.is_owner=1 -- The owner of the position
		[[and co.id = {{company_id}}]]
		[[and pb.position_id = {{position_id}}]]
		[[and seeker.id in ({{seeker_id}})]]  
		[[and concat(seeker.first_name, ' ', seeker.last_name) regexp {{seeker_name}}]]
		[[and tl_info.id in ({{team_leader_id}})]]  
		[[and concat(tl_info.first_name, ' ', tl_info.last_name) regexp {{team_leader}}]]
		[[and sm_info.id in ({{search_manager_id}})]]  
		[[and concat(sm_info.first_name, ' ', sm_info.last_name) regexp {{search_manager}}]]
		[[and {{date_range}}]] -- start date

	group by
	      co.id -- Company Id
	    , pso.caliber_id -- Position Owner
		, bc.batch_id
		, pb.position_id
		, tl_info.id
		
) as temp