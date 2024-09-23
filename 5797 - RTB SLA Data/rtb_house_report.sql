-- RTB House Report --

select 
    p.id as position_id
    , p.name as position_name
    , concat(ca.first_name, ' ', ca.last_name) as position_owner
    , date(p.created) as position_created
    , count(distinct bc.caliber_id) as total_leads_first_7_days
    , count(distinct b.id) as batches_sent_first_7_days
    , concat('https://admin.fetcher.ai/positions/',p.id) as Link
from position_notes pn
left join positions p on p.id = pn.position_id 
left join companies c on c.id = p.company_id  
left join positions_batches pb on pb.position_id = p.id 
left join batch_candidates as bc on bc.batch_id = pb.batch_id 
left join batches b on b.id = bc.batch_id
left join positions_side_owners as pso on
        pso.position_id = p.id
        and pso.is_owner = 1
left join calibers ca on ca.id = pso.caliber_id 
where 1=1
    and c.id = 581008 -- RTB House
    and (lower(pn.note) like '%pipeline%')
    and b.status = 2 -- Batch Sent
    and b.created <= DATE_ADD(p.created, INTERVAL 7 DAY)
group by 
    p.id -- grouping by position
order by
    total_leads_first_7_days desc; 
