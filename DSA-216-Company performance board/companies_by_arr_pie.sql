select
    metabase.company_performance_board.arr_tier as "ARR tier"
    , count(distinct metabase.company_performance_board.company_name) as "Count"
from report_db.metabase.company_performance_board
where 1=1
    [[and {{company_id}}]]
    [[and {{company_name}}]]
    [[and {{date}}]]
    [[and {{contract_status}}]]
    [[and {{size_tier}}]]
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
    metabase.company_performance_board.arr_tier
order by
    count(distinct metabase.company_performance_board.company_name) asc
;
