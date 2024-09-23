select
concat(users.first_name,' ', users.last_name) as 'Owner Name', 
p.name,
p.id,
case 
    when p.status = 1 then 'new' 
    when p.status = 2 then 'open' 
    when p.status = 4 then 'hold' 
end as status, 

-- added
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (101) [[and ce.created between {{start_date}} and {{end_date}}]] ) as added,

-- emailed
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (1,2) [[and ce.created between {{start_date}} and {{end_date}}]] ) as emailed,

-- opens (at least one open per position / caliber id)
(select count(distinct tp.caliber_id) from tracking_pixels tp where tp.position_id = p.id and tp.status=1 [[and tp.modified between {{start_date}} and {{end_date}}]] ) as opened,

-- replies
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (14) [[and ce.created between {{start_date}} and {{end_date}}]] ) as responded,

-- like
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (201) [[and ce.created between {{start_date}} and {{end_date}}]] ) as liked,

-- dislike
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (202) [[and ce.created between {{start_date}} and {{end_date}}]] ) as disliked,

-- interested
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (408) [[and ce.created between {{start_date}} and {{end_date}}]] ) as interested,

-- email rate
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (1,2) [[and ce.created between {{start_date}} and {{end_date}}]] )/
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (101) [[and ce.created between {{start_date}} and {{end_date}}]] ) as email_rate,

-- open rate
(select count(distinct tp.caliber_id) from tracking_pixels tp where tp.position_id = p.id and tp.status=1 [[and tp.modified between {{start_date}} and {{end_date}}]])/
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (1,2) [[and ce.created between {{start_date}} and {{end_date}}]] ) as open_rate,

-- response rate
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (14) [[and ce.created between {{start_date}} and {{end_date}}]] )/
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (1,2) [[and ce.created between {{start_date}} and {{end_date}}]] ) as response_rate,

-- conversion rate (replied / opened)
(select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (14) [[and ce.created between {{start_date}} and {{end_date}}]] )/
(select count(distinct tp.caliber_id) from tracking_pixels tp where tp.position_id = p.id and tp.status=1 [[and tp.modified between {{start_date}} and {{end_date}}]]) as conv_rate

from positions p inner join 
-- candidate_events ce_add on p.id = ce_add.position_id and ce_add.event_id = 101 inner join
-- calibers c on ce_add.caliber_id = c.id inner join
-- oauth_users u on c.id = u.id inner join
companies on companies.id=p.company_id inner join
calibers users on p.owner_id = users.id inner join
oauth_users uu on users.id = uu.id

where
p.status in (1,2,4)
[[ and uu.username regexp {{email}}]]
[[and companies.name regexp {{company}}]] -- Add more filters
[[and p.id = {{position}}]]


limit 2000