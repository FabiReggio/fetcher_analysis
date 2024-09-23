-------- 4915 - What day of the week are candidates most responsive? -----------

select 
    case 
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 0 then 'MONDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 1 then 'TUESDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 2 then 'WEDNESDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 3 then 'THURSDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 4 then 'FRIDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 5 then 'SATURDAY'
        when WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)) = 6 then 'SUNDAY'
    end as week_candidate_localtime,
    count(*) as replies
from candidate_events ce
left join calibers ca on ce.caliber_id = ca.id
left join locations as l on l.id=ca.location_id
left join timezones as tz on tz.id = l.timezone_id
where 1=1
and ce.event_id = 14 
and year(ce.created) >= [[{{year}}]]
group by WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset))
order by WEEKDAY(CONVERT_TZ (ce.created, '+00:00', tz.offset)); 

