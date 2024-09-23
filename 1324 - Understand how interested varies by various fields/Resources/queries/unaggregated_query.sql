select
    cis.candidate_id
    , cis.position_id
    , p.name as position_name
    , p.remote_work
    , p.visa_sponsorship
    , p.relocation
    , pos_comp.name as company_name
    , pos_comp.founded
    , case
        when (year(current_date()) - pos_comp.founded) < 5 then '0-5'
        when (year(current_date()) - pos_comp.founded) >= 5 and (year(current_date()) - pos_comp.founded) < 10 then '5-10'
        when (year(current_date()) - pos_comp.founded) >= 10 and (year(current_date()) - pos_comp.founded) < 20 then '10-20'
        when (year(current_date()) - pos_comp.founded) >= 20 then '+20'
        else 'check_for_error'
    end as company_age
    , pos_comp.employees as company_size
    , CASE
        when pos_comp.employees < 10 then '0 - 10'
        when pos_comp.employees >= 10 and pos_comp.employees < 20 then '10 - 20'
        when pos_comp.employees >= 20 and pos_comp.employees < 50 then '20 - 50'
        when pos_comp.employees >= 50 and pos_comp.employees < 100 then '50 - 100'
        when pos_comp.employees >= 100 and pos_comp.employees < 500 then '100 - 500'
        when pos_comp.employees >= 500 and pos_comp.employees < 1000 then '500 - 1000'
        when pos_comp.employees >= 1000 and pos_comp.employees < 5000 then '1000 - 5000'
        when pos_comp.employees >= 5000 then '+5000'
        else 'check_for_error'
    end as company_size_range
    , loc.name as location
    , ind.name as industry
    , cis.status as interest_flag
-- select count(*)
from candidate_interested_status as cis
left join positions as p on p.id = cis.position_id
left join companies as pos_comp on pos_comp.id = p.company_id
left join industries as ind on ind.id = p.industry_id
left join locations as loc on loc.id = p.location_id
where 1=1
    and loc.country_code = 'USA'
    and loc.is_country is NULL
    and pos_comp.employees != 0