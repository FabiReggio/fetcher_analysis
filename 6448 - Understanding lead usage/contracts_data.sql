select
    temp.*
from (
    select
        companies.ID as customer_id
        , companies.name as customer_name
        , contract_trackings.contract_id as contract_id
        , contracts.start_date as start_date
        , coalesce(
            date_add(contracts.end_date, interval dur_addon.amount day)
            , contracts.end_date
        ) as end_date
        , case
            when last_contract.date = contracts.start_date then 'No'
            else 'Yes'
        end as has_subsequent_contract
        , case contracts.status
            when 0 then 'Expired'
            when 1 then 'Active'
            when 2 then 'Company revoked'
            when 3 then 'Inactive'
            when 4 then 'Canceled'
            else null
        end as contract_status
        , sum(
            coalesce(contracts.price, 0) +
            coalesce(dur_addon.price_addon, 0) +
            coalesce(ml_addon.price_addon, 0) +
            coalesce(seats_addon.price_addon, 0) +
            coalesce(ssl_addon.price_addon, 0)
        ) as price
        , sum(contract_trackings.managed_leads_paid) as managed_leads_paid
        , sum(contract_trackings.managed_leads_used) as managed_leads_used
        , sum(contract_trackings.self_served_leads_paid) as self_served_leads_paid
        , sum(contract_trackings.self_served_leads_used) as self_served_leads_used
    from contracts
    left join contract_trackings on contract_trackings.contract_id = contracts.id
    left join companies on contracts.company_id = companies.id
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
    ) as dur_addon on dur_addon.contract_id = contracts.id
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
    ) as ml_addon on ml_addon.contract_id = contracts.id
    left join (
        select
            csslao.contract_id
            , sum(lao.amount) as amount
            , sum(csslao.price) as price_addon
        from contract_self_served_lead_add_ons as csslao
        left join lead_add_ons as lao on lao.id = csslao.lead_add_on_id
        group by
            csslao.contract_id
    ) as ssl_addon on ssl_addon.contract_id = contracts.id
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
    ) as seats_addon on seats_addon.contract_id = contracts.id
    left join (
        select
            inner_cont.company_id
            , max(inner_cont.start_date) as date
        from contracts as inner_cont
        group by
            inner_cont.company_id
    ) as last_contract on last_contract.company_id = contracts.company_id
    where true
        -- and contracts.company_id in (581008, 922700, 1173665) -- for testing
        and contracts.status in (
            0 -- EXPIRED
            , 1 -- ACTIVE
        )
    group by
        companies.id
        , contracts.id
) as temp
where true
    [[and {{company_id}}]]
    [[and lower(temp.contract_status) = lower({{contract_status}})]]
    [[and lower(temp.has_subsequent_contract) = lower({{subsequent_contract}})]]
order by
    temp.customer_id
    , temp.contract_id