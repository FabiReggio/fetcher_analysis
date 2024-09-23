select
    temp.company_id as "Company ID"
    , temp.company_name as "Company Name"
    , year(b.modified) as "Year"
    , monthname(b.modified) as "Month"
    , temp.contract_id as contract_id
    , temp.start_date as start_date
    , temp.end_date as end_date
    , temp.contract_status_str as "Contract Status"
    , period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m')) as "Contract Period (Months)"
    , temp.price as "Full Contract Price"
    , (temp.price / period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m'))) as "Contract Price per Month" 
    , temp.managed_leads_paid as "Fetcher Leads Paid"
    , (temp.managed_leads_paid / period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m'))) as "Fetcher Leads Paid per Month" 
    , temp.managed_leads_used as "Fetcher Leads Used"
    , case 
        when temp.contract_status = 1  then (temp.managed_leads_used / period_diff(date_format(current_date(),'%Y%m'), date_format(temp.start_date, '%Y%m')))
        when temp.contract_status != 1 then (temp.managed_leads_used / period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m'))) 
        else null
    end as "Fetcher Leads Used per Month"
    , temp.self_served_leads_paid as "Extension Leads Paid"
    , (temp.self_served_leads_paid / period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m'))) as "Extension Leads Paid per Month" 
    , temp.self_served_leads_used as "Extension Leads Used"
    , case 
        when temp.contract_status = 1  then (temp.self_served_leads_used / period_diff(date_format(current_date(),'%Y%m'), date_format(temp.start_date, '%Y%m')))
        when temp.contract_status != 1 then (temp.self_served_leads_used / period_diff(date_format(temp.end_date, '%Y%m'), date_format(temp.start_date, '%Y%m'))) 
        else null
    end as "Extension Leads Used per Month"
    , count(distinct bc.caliber_id) as "Leads Sent per Month"
from (
    select
        companies.id as company_id
        , companies.name as company_name
        , contract_trackings.contract_id as contract_id
        , contracts.start_date as start_date
        , coalesce(date_add(contracts.end_date, interval dur_addon.amount day), contracts.end_date) as end_date
        , (contracts.price + coalesce(ml_addon.price_addon, 0) + coalesce(ssl_addon.price_addon, 0) + coalesce(seats_addon.price_addon, 0) + coalesce(dur_addon.price_addon, 0)) as price
        , contracts.status as contract_status
        , case
            when contracts.status = 0 then 'EXPIRED'
            when contracts.status = 1 then 'ACTIVE'
            when contracts.status = 4 then 'CANCELED'
            else null
        end as contract_status_str
        , sum(contract_trackings.managed_leads_used) as managed_leads_used
        , sum(contract_trackings.managed_leads_paid) as managed_leads_paid
        , sum(contract_trackings.self_served_leads_used) as self_served_leads_used
        , sum(contract_trackings.self_served_leads_paid) as self_served_leads_paid
    from contracts
    left join contract_trackings on contract_trackings.contract_id = contracts.id
    left join companies on contracts.company_id = companies.id
    
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
    where 1=1
        and contracts.status not in (2, 3) -- Excluding COMPANY REVOKED and INACTIVE contracts
        [[and {{company_id}}]]
        [[and {{company_name}}]]
        [[and {{contract_status}}]]
    group by
        companies.name
        , contract_trackings.contract_id
) as temp
-- CUSTOMER COMPANIES
left join customer_companies as cc on cc.company_id = temp.company_id
-- BATCHES DATA 
left join positions_side_owners as pso on pso.caliber_id = cc.caliber_id 
left join positions_batches pb on pso.position_id = pb.position_id 
left join batch_candidates bc on bc.batch_id = pb.batch_id        
left join batches as b on b.id = bc.batch_id
    
where 1=1
    and b.status = 2
    and b.modified between temp.start_date and date_sub(temp.end_date, interval 1 month)

group by 
    temp.company_id
    , temp.contract_id
    , year(b.modified)
    , month(b.modified)
order by 
    temp.end_date
    , temp.contract_id
    , year(b.modified)
    , month(b.modified)  
    
