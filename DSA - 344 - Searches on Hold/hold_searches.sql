select 
    c.id as company_id
    , c.name as company_name
    , p.id as position_id 
    , p.name as position_name 
    , p.owner_id as position_owner_id
    , case
		when p.status = 1 or p.status = 2 then 'Open' 
		when p.status = 3 then 'Closed'
		when p.status = 4 then 'Hold'
	  end as position_status
    , concat(ca.first_name, ' ', ca.last_name) as owner_name 
    , date(p.created) as created_date
    , date(p.modified) as modified_date
from positions p
left join calibers ca on ca.id = p.owner_id
left join companies c ON p.company_id = c.id
where true 
and p.outreach_type = 0 -- Only Search Positions
and p.name not like '%demo%'
[[and c.id = {{company_id}}]]  
[[and c.name = {{company_name}}]]
[[and p.id = {{position_id}}]]
[[and p.owner_id = {{position_owner_id}}]]
[[and p.status = {{position_status}}]]
order by 
    company_id
    , position_id;
