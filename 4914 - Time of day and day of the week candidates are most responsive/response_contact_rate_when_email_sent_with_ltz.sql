-- Response, Contact rate based on time of day that email is sent - with local timezone

select 
    hour(CONVERT_TZ (bc.contact_date, '+00:00', tz.offset)) as hour_contact_date_localtime
    , sum(case when bc.contact_status >= 1 then 1 else 0 end) as contacted
    , sum(case when bc.responded = 1 then 1 else 0 end) as responses
    , sum(case when bc.contact_status >= 1 then 1 else 0 end)/count(bc.caliber_id) as contact_rate
    , sum(case when bc.responded = 1 then 1 else 0 end) / sum(case when bc.contact_status >= 1 then 1 else 0 end) as response_rate
from batch_candidates bc
left join calibers ca on bc.caliber_id = ca.id
left join locations as l on l.id=ca.location_id
left join timezones as tz on tz.id = l.timezone_id
where 1=1 
    and bc.contact_date!='0000-00-00 00:00:00'
    and year(bc.created) >= [[{{year}}]]
group by hour_contact_date_localtime
having hour_contact_date_localtime >=0;
