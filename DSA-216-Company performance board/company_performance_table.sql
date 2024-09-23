select
    metabase.company_performance_board.company_id as "Company ID"
    , metabase.company_performance_board.company_name as "Company name"
    , metabase.company_performance_board.industry as "Industry"
    , metabase.company_performance_board.arr_tier as "Arr tier"
    , metabase.company_performance_board.size_tier as "Size tier"
    -- , metabase.company_performance_board.health_score as "Health score"
    , metabase.company_performance_board.open_searches as "Open searches"
    , metabase.company_performance_board.closed_searches as "Closed searches"
    , div0(
        sum(metabase.company_performance_board.approved)
        , sum(metabase.company_performance_board.vetted)
    ) as "Approved rate"
    , div0(
        sum(metabase.company_performance_board.vetted)
        , sum(metabase.company_performance_board.total_leads)
    ) as "Vetted rate"
    , div0(
        sum(metabase.company_performance_board.contacted)
        , sum(metabase.company_performance_board.vetted)
    ) as "Contacted rate"
    , div0(
        sum(metabase.company_performance_board.open_emails_count)
        , sum(metabase.company_performance_board.contacted)
    ) as "Opened email rate"
    , div0(
        sum(metabase.company_performance_board.likes)
        , sum(metabase.company_performance_board.vetted)
    ) as "Like rate"
    , div0(
        sum(metabase.company_performance_board.dislikes)
        , sum(metabase.company_performance_board.vetted)
    ) as "Dislike rate"
    , div0(
        sum(metabase.company_performance_board.responded)
        , sum(metabase.company_performance_board.contacted)
    ) as "Responded rate"
    , div0(
        sum(metabase.company_performance_board.interested)
        , sum(metabase.company_performance_board.responded)
    ) as "Interested rate"
    -- , metabase.company_performance_board.hires_rate as "Hires rate"
    , metabase.company_performance_board.contract_status as "Contract status"
    , metabase.company_performance_board.country as "Country"
    , metabase.company_performance_board.state as "State"
    , metabase.company_performance_board.city as "City"
    , metabase.company_performance_board.first_contract_start_date as "First contract start date"
    , metabase.company_performance_board.last_contract_start_date as "Last contract start date"
    , metabase.company_performance_board.last_contract_end_date as "Last contract end date"
    , metabase.company_performance_board.admin_link as "Admin link"
from report_db.metabase.company_performance_board
where 1=1
    [[and {{company_id}}]]
    [[and {{company_name}}]]
    [[and {{date}}]]
    [[and {{contract_status}}]]
    [[and {{size_tier}}]]
    [[and {{arr_tier}}]]
    [[and {{country}}]]
    and report_db.metabase.company_performance_board.company_id in (
        select distinct
            report_db.metabase.company_position_role_vw.company_id
        from report_db.metabase.company_position_role_vw
        where true
            [[and {{members_first_name}}]]
            [[and {{members_last_name}}]]
            [[and {{members_full_name}}]]
            [[and {{member_role}}]]
    )
    and metabase.company_performance_board.first_contract_start_date is not null
group by
    metabase.company_performance_board.company_id
    , metabase.company_performance_board.company_name
    , metabase.company_performance_board.industry
    , metabase.company_performance_board.arr_tier
    , metabase.company_performance_board.size_tier
    , metabase.company_performance_board.open_searches
    , metabase.company_performance_board.closed_searches
    , metabase.company_performance_board.contract_status
    , metabase.company_performance_board.country
    , metabase.company_performance_board.state
    , metabase.company_performance_board.city
    , metabase.company_performance_board.first_contract_start_date
    , metabase.company_performance_board.last_contract_start_date
    , metabase.company_performance_board.last_contract_end_date
    , metabase.company_performance_board.admin_link
order by
    coalesce(metabase.company_performance_board.open_searches, 0) desc
;