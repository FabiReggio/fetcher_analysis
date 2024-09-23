select
    cand_comp.name as from_company
    , p.company_name_url as to_company
    , avg(pos_comp.employees)
    , avg(cand_comp.employees)
    , avg(pos_comp.employees) / avg(cand_comp.employees)
    , sum(cis.status) / sum(1) as interest_rate
from candidate_interested_status as cis
left join positions as p on p.id = cis.position_id
left join companies as pos_comp on pos_comp.id = p.company_id
left join caliber_companies as cc on cc.caliber_id = cis.candidate_id
left join companies as cand_comp on cand_comp.id = cc.company_id
left join locations as loc on loc.id = p.location_id
where 1=1
    and loc.country_code = 'USA'
    and (cc.start_date != 0 and cc.end_date = 0)
    and cc.position != ''
    and loc.is_country is NULL
group by 1, 2
having 1=1
    and (avg(pos_comp.employees) / avg(cand_comp.employees)) is not null
    and avg(pos_comp.employees) != 0