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