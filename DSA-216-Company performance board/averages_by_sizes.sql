select
    metabase.company_performance_board.size_tier as "Size tier"
    , avg(metabase.company_performance_board.open_searches) as "Open searches"
    , div0(
        sum(metabase.company_performance_board.vetted)
        , sum(metabase.company_performance_board.total_leads)
    ) as "Vetted rate"
    , div0(
        sum(metabase.company_performance_board.contacted)
        , sum(metabase.company_performance_board.vetted)
    ) as "Contacted rate"
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
    -- , max(metabase.company_performance_board.hires) as "Hires rate"
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
    metabase.company_performance_board.size_tier
order by
    metabase.company_performance_board.size_tier
;