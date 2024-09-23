select 
    day(cm.created) as day
    , hour(cm.created) as hour
    , count(*) as email_sent
from candidate_message cm
where 1=1
and cm.email_type in (0,1,2,3,4,5)
[[AND DATE(cm.created) >= {{from}} ]]
[[AND DATE(cm.created) < {{until}} ]]
group by 
    day(cm.created)
    , hour(cm.created)
order by 
    day(cm.created)
    , hour(cm.created) asc;