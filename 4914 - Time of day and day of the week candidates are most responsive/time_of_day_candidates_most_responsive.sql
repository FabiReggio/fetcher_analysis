-------- 4914 - What time of day are candidates most responsive? -----------

select 
    hour(CONVERT_TZ (ce.created, '+00:00', tz.offset)) as hour_candidate_localtime,
    count(*) as num_of_replies
from candidate_events ce
left join calibers ca on ce.caliber_id = ca.id
left join locations as l on l.id=ca.location_id
left join timezones as tz on tz.id = l.timezone_id
left join positions as p on p.id = ce.position_id
left join companies on companies.id = p.company_id 
where 1=1
    and ce.event_id = 14 
    [[and {{company_id}}]]
    [[and {{company_name}}]]
group by hour_candidate_localtime;

