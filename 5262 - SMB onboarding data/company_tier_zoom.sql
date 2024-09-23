select
    temp.company_id as 'Company ID'
    , temp.company_name as 'Company name'
    , case
        when temp.annual_recurring_revenue >= 25000 then 'Enterprise'
        when temp.annual_recurring_revenue >= 12500 and temp.annual_recurring_revenue < 25000 then 'Mid-Market'
        when temp.annual_recurring_revenue < 12500 then 'SMB'
    end as 'Tier'
    , avg(temp.days_until_first_pos) as 'Average days until first search'
    , (
        sum(if(
            least(
                coalesce(temp.days_to_outlook_sync, {{days_within}} + 1)
                , coalesce(temp.days_to_gmail_sync, {{days_within}} + 1)
            ) <= {{days_within}}
            , 1
            , 0
        ))
        /
        count(temp.company_id)
    ) as 'Email sync within {{days_within}} days'
    , (
        sum(if(
            least(
                coalesce(temp.days_to_greenhouse_sync, {{days_within}} + 1)
                , coalesce(temp.days_to_smart_recruiters_sync, {{days_within}} + 1)
                , coalesce(temp.days_to_smashfly_sync, {{days_within}} + 1)
                , coalesce(temp.days_to_compas_sync, {{days_within}} + 1)
                , coalesce(temp.days_to_lever_sync, {{days_within}} + 1)
            ) <= {{days_within}}
            , 1
            , 0
        ))
        /
        count(temp.company_id)
    ) as 'ATS sync within {{days_within}} days'
from (
    select
        cc.company_id
        , companies.name as company_name
        , cc.caliber_id
        , cont.start_date
        -- , cont.end_date
        , cont.annual_recurring_revenue
        , datediff(
            min(p.created)
            , cc.created
        ) as days_until_first_pos
        , datediff(min(oat.created), cc.created) as days_to_outlook_sync
        , min(oat.created) as outlook_sync_date
        , datediff(min(gat.created), cc.created) as days_to_gmail_sync
        , min(gat.created) as gmail_sync_date
        , datediff(min(gh.created), cc.created) as days_to_greenhouse_sync
        , min(gh.created) as greenhouse_sync_date
        , datediff(min(sr.created), cc.created) as days_to_smart_recruiters_sync
        , min(sr.created) as smart_recruiters_sync_date
        , datediff(min(su.created), cc.created) as days_to_smashfly_sync
        , min(su.created) as smashfly_sync_date
        , datediff(min(cu.created), cc.created) as days_to_compas_sync
        , min(cu.created) as compas_sync_date
        , datediff(min(lu.created), cc.created) as days_to_lever_sync
        , min(lu.created) as lever_sync_date
    from customer_companies as cc
    left join companies on companies.id = cc.company_id
    inner join (
        select
            inner_cont.company_id
            , min(inner_cont.start_date) as start_date
            , min(coalesce(
                date_add(inner_cont.end_date, interval dur_addon.amount day)
                , inner_cont.end_date
            )) as end_date
            , (
                sum(inner_cont.price
                    + coalesce(ml_addon.price_addon, 0)
                    + coalesce(ssl_addon.price_addon, 0)
                    + coalesce(seats_addon.price_addon, 0)
                    + coalesce(dur_addon.price_addon, 0)
                ) -- corrected contract price
                / sum(datediff(
                    coalesce(date_add(inner_cont.end_date, interval dur_addon.amount day) , inner_cont.end_date)
                    , inner_cont.start_date
                )) -- days counting all the company's contracts
                * 365
            ) as annual_recurring_revenue
        from contracts as inner_cont
        -- LEADS ADD ONS
        left join (
            select
                cmlao.contract_id
                , sum(lao.amount) as amount
                , sum(cmlao.price) as price_addon
            from contract_managed_lead_add_ons as cmlao
            left join lead_add_ons as lao on lao.id = cmlao.lead_add_on_id
            group by
                cmlao.contract_id
        ) as ml_addon on ml_addon.contract_id = inner_cont.id
        left join (
            select
                csslao.contract_id
                , sum(lao.amount) as amount
                , sum(csslao.price) as price_addon
            from contract_self_served_lead_add_ons as csslao
            left join lead_add_ons as lao on lao.id = csslao.lead_add_on_id
            group by
                csslao.contract_id
        ) as ssl_addon on ssl_addon.contract_id = inner_cont.id
        -- SEATS ADD ONS
        left join (
            select
                csao.contract_id
                , sum(sao.amount) as amount
                , sum(csao.price) as price_addon
            from contract_seat_add_ons as csao
            left join seats_add_ons as sao on sao.id = csao.seat_add_on_id
            group by
                csao.contract_id
        ) as seats_addon on seats_addon.contract_id = inner_cont.id
        -- DURATION ADD ONS
        left join (
            select
                cdao.contract_id
                , sum(dao.amount) as amount
                , sum(cdao.price) as price_addon
            from contract_duration_add_ons as cdao
            left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
            group by
                cdao.contract_id
        ) as dur_addon on dur_addon.contract_id = inner_cont.id
        where true
            and inner_cont.status in (0, 1)
        group by
            inner_cont.company_id
    ) as cont on cont.company_id = cc.company_id
    left join outlook_access_tokens as oat on
        cc.caliber_id = oat.caliber_id
        and oat.created >= cont.start_date
    left join google_access_tokens as gat on
        cc.caliber_id = gat.caliber_id
        and gat.created >= cont.start_date
    left join greenhouse_access_tokens as gh on
        gh.customer_id = cc.caliber_id
        and cc.created >= cont.start_date
    left join smart_recruiters_tokens as sr on
        sr.customer_id = cc.caliber_id
        and cc.created >= cont.start_date
    left join smashfly_users as su on
        su.customer_id = cc.caliber_id
        and cc.created >= cont.start_date
    left join compas_users as cu on
        cu.customer_id = cc.caliber_id
        and cc.created >= cont.start_date
    left join lever_users as lu on
        lu.customer_id = cc.caliber_id
        and lu.created >= cont.start_date
    left join positions_side_owners as pso on
        pso.caliber_id = cc.caliber_id
        and pso.is_owner = 1
        and pso.created between cont.start_date and cont.end_date
    left join positions as p on p.id = pso.position_id
    where true
        and {{onboarding_date}}
    group by
        cc.company_id
        , cc.caliber_id
) as temp
where true
    [[and (case
            when temp.annual_recurring_revenue >= 25000 then 'Enterprise'
            when temp.annual_recurring_revenue >= 12500 and temp.annual_recurring_revenue < 25000 then 'Mid-Market'
            when temp.annual_recurring_revenue < 12500 then 'SMB'
        end) = {{tier}}]]
group by
    temp.company_id