-- Mixpanel Active Users Last N Days

select * 
from report_db.metabase.mp_user_event_dates_vw
where 1=1
    and date(last_event_date) >= (current_date()-[[{{Days}}]])
    [[and {{company_id}}]]
    [[and {{company_name}}]]
    [[and {{customer_id}}]]
    [[and {{customer_name}}]]