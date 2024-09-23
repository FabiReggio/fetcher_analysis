-- Positions Information

select 
    positions.id as position_id
    , positions.name as position_name
    , case 
		when positions.status = 1 then 'New'
		when positions.status = 2 then 'Open'
		when positions.status = 3 then 'Closed'
		when positions.status = 4 then 'Hold'
	end as position_status
    , case 
	  when b.type=1 
        then 'Fetcher Search'
      when b.type=2 and b.name="Copied Profiles" 
        then 'Fetcher Search' 
      when b.type=2 and b.name="Campaign Batch" 
        then 'Campaign' 
      when b.type=3 
        then 'Extension'
      else 'Fetcher Search'
     end as search_type
    , companies.id as company_id
    , companies.name as company_name
    , seekers.id as seeker_id
	, concat(seekers.first_name, ' ', seekers.last_name) as seekers_name
	, concat(tl_info.first_name, ' ', tl_info.last_name) as team_leader
	, concat(sm_info.first_name, ' ', sm_info.last_name) as search_manager
from positions 
left join positions_batches pb on pb.position_id = positions.id
left join batches b on pb.batch_id = b.id
-- INFO ABOUT THE FETCHER TEAM
left join position_members as pm on
    positions.id = pm.position_id
	and pm.role_id = 1 -- Seeker role
left join calibers as seekers on seekers.id = pm.caliber_id -- info about the seeker
-- INFO ABOUT THE TEAM LEADER
left join position_members as tl on 
	tl.position_id = positions.id
	and tl.role_id = 2 -- Team Leader role
left join calibers as tl_info on tl_info.id = tl.caliber_id -- data about the Team leader
-- INFO ABOUT THE SEARCH MANAGER
left join position_members as sm on 
	sm.position_id = positions.id
	and sm.role_id = 3 -- Search Manager role
left join calibers as sm_info on sm_info.id = sm.caliber_id -- data about the Search Manager
-- COMPANY INFORMATION
left join positions_side_owners pso on
    pso.position_id = positions.id
    and pso.is_owner = 1
left join customer_companies cc on 
    cc.caliber_id = pso.caliber_id
left join companies on 
    cc.company_id = companies.id 
where 1=1
    [[and {{position_id}}]]
    [[and {{company_id}}]]
    [[and {{company_name}}]]
    [[and concat(tl_info.first_name, ' ', tl_info.last_name) regexp {{team_leader}}]]
    [[and concat(sm_info.first_name, ' ', sm_info.last_name) regexp {{search_manager}}]]
    [[and seekers.id = {{seeker_id}}]]
group by 
    positions.id
    , seekers.id
order by 
    positions.created desc;
