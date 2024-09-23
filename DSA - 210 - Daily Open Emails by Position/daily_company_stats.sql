-- Daily Company Stats - Metabase

select *
from report_db.metabase.daily_company_full_stats_vw
where 1=1
    [[and {{company_id}}]]
    [[and event_date between {{start_date}} and {{end_date}}]]
