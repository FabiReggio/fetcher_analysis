select
    final.company_id as 'Company ID'
    , final.company_name as 'Company name'
    , final.contract_id as 'Contract ID'
    , final.start_date as 'Start date'
    , final.end_date as 'End date'
    , final.duration_days as 'Duration days'
    , final.duration_months as 'Contract duration (months)'
    , final.managed_leads_paid as 'Total Fetcher leads avail'
    , convert(final.managed_leads_per_month, SIGNED) as 'Allowed Fetcher leads/month'
    , final.managed_leads_usage_perc as '% Fetcher leads usage'
    , convert(final.managed_leads_per_month * final.managed_leads_usage_perc, SIGNED) as 'Expected Fetcher lead usage'
    , final.self_served_leads_paid as 'Total Extension leads avail'
    , convert(final.self_served_leads_per_month, SIGNED) as 'Allowed Extension leads/month'
    , final.self_served_leads_usage_perc as '% Extension leads usage'
    , convert(final.self_served_leads_per_month * final.self_served_leads_usage_perc, SIGNED) as 'Expected Extension lead usage'
from (
    select
        c.company_id
        , companies.name as company_name
        , c.id as contract_id
        , c.start_date
        , coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date) as end_date
        , DATEDIFF(
            coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date)
            , c.start_date
        ) as duration_days
        , period_diff(
                date_format(
                    coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date)
                    , '%Y%m'
                )
                , date_format(c.start_date, '%Y%m')
        ) as duration_months
        , ct.managed_leads_paid as managed_leads_paid
        , ct.self_served_leads_paid as self_served_leads_paid
        , (
            ct.managed_leads_paid
            /
            period_diff(
                date_format(
                    coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date)
                    , '%Y%m'
                )
                , date_format(c.start_date, '%Y%m')
            )
        ) as managed_leads_per_month
        , (
            ct.self_served_leads_paid
            /
            period_diff(
                date_format(
                    coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date)
                    , '%Y%m'
                )
                , date_format(c.start_date, '%Y%m')
            )
        ) as self_served_leads_per_month
        , usage_perc.managed_leads_usage_perc
        , usage_perc.self_served_leads_usage_perc
    from contracts as c
    left join contract_trackings as ct on ct.contract_id = c.id
    left join companies on c.company_id = companies.id
    -- START DURATION AND LEADS CORRECTIONS
    -- duration corrections
    left join (
        select
            cdao.contract_id
            , sum(dao.amount) as amount
        from contract_duration_add_ons as cdao
        left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
        group by
            cdao.contract_id
    ) as dur_addon on dur_addon.contract_id = c.id
    -- leads corrections
    left join (
        select
            cmlao.contract_id
            , sum(lao.amount) as amount
        from contract_managed_lead_add_ons as cmlao
        left join lead_add_ons as lao on lao.id = cmlao.lead_add_on_id
        group by
            cmlao.contract_id
    ) as ml_addon on ml_addon.contract_id = c.id
    left join (
        select
            csslao.contract_id
            , sum(lao.amount) as amount
        from contract_self_served_lead_add_ons as csslao
        left join lead_add_ons as lao on lao.id = csslao.lead_add_on_id
        group by
            csslao.contract_id
    ) as ssl_addon on ssl_addon.contract_id = c.id
    -- END DURATION AND LEADS CORRECTIONS
    /*
        Getting pasted leads usage percentage by company to estimate future behavior
    */
    left join (
        select
            inner_c.company_id
            , (
                sum(inner_ct.managed_leads_used)
                /
                coalesce(
                    sum(inner_ct.managed_leads_paid) + inner_ml_addon.amount
                    , sum(inner_ct.managed_leads_paid)
                )
            ) as managed_leads_usage_perc
            , (
                sum(inner_ct.self_served_leads_used)
                /
                coalesce(
                    sum(inner_ct.self_served_leads_paid) + inner_ssl_addon.amount
                    , sum(inner_ct.self_served_leads_paid)
                )
            ) as self_served_leads_usage_perc
        from contracts as inner_c
        left join contract_trackings as inner_ct on inner_ct.contract_id = inner_c.id
        -- START DURATION AND LEADS CORRECTIONS
        -- leads corrections
        left join (
            select
                cmlao.contract_id
                , sum(lao.amount) as amount
            from contract_managed_lead_add_ons as cmlao
            left join lead_add_ons as lao on lao.id = cmlao.lead_add_on_id
            group by
                cmlao.contract_id
        ) as inner_ml_addon on inner_ml_addon.contract_id = inner_c.id
        left join (
            select
                csslao.contract_id
                , sum(lao.amount) as amount
            from contract_self_served_lead_add_ons as csslao
            left join lead_add_ons as lao on lao.id = csslao.lead_add_on_id
            group by
                csslao.contract_id
        ) as inner_ssl_addon on inner_ssl_addon.contract_id = inner_c.id
        -- END DURATION AND LEADS CORRECTIONS
        group by
            inner_c.company_id
    ) as usage_perc on usage_perc.company_id = c.company_id
    where 1=1
        and c.status = 1 -- ACTVE contracts
        [[and c.company_id = {{company_id}}]]
        [[and {{company_name}}]]
    group by
        c.company_id
        , c.id
) as final
order by
    final.managed_leads_paid desc