-- Daily Company Position Stats - Metabase

select *
from report_db.metabase.daily_company_position_full_stats_vw
where 1=1
    [[and company_id = {{company_id}}]]
    [[and {{position_id}}]]
    [[and event_date between {{start_date}} and {{end_date}}]]
