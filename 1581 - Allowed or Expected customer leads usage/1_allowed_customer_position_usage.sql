select
    c.company_id
    , c.start_date
    , coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date) as end_date
    , DATEDIFF(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), c.start_date) as duration_days
    , period_diff(
        date_format(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), '%Y%m')
        , date_format(c.start_date, '%Y%m')
    ) as duration_months
    , ct.managed_leads_paid as managed_leads_paid
    , ct.self_served_leads_paid as self_served_leads_paid
    , (
        ct.managed_leads_paid
        /
        period_diff(
            date_format(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), '%Y%m')
            , date_format(c.start_date, '%Y%m')
        )
    ) as '# Fetcher leads allowed/month'
    , (
        ct.self_served_leads_paid
        /
        period_diff(
            date_format(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), '%Y%m')
            , date_format(c.start_date, '%Y%m')
        )
    ) as '# Extension leads allowed/month'
    , cast(
        ct.managed_leads_paid
        /
        (period_diff(
            date_format(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), '%Y%m')
            , date_format(c.start_date, '%Y%m')
        ) * {{leads_per_month}}
        )
    as signed ) as '# Fetcher positions allowed/month'
    , cast(
        ct.self_served_leads_paid
        /
        (period_diff(
            date_format(coalesce(date_add(c.end_date, interval dur_addon.amount day), c.end_date), '%Y%m')
            , date_format(c.start_date, '%Y%m')
        ) * {{leads_per_month}}
        )
    as signed ) as '# Extension positions allowed/month'
from contracts as c
left join contract_trackings as ct on ct.contract_id = c.id
left join companies as comp on c.company_id = comp.id
-- DURATION ADD ONS
left join (
    select
        cdao.contract_id
        , sum(dao.amount) as amount
    from contract_duration_add_ons as cdao
    left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
    group by
        cdao.contract_id
) as dur_addon on dur_addon.contract_id = c.id
-- LEADS ADD ONS
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
where 1=1
    and c.status = 1