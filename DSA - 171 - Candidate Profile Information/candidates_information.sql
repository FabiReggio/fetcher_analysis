select 
    positions.company_id
    , positions.id as position_id
    , positions.name as position_name
    , c.id as candidate_id
    , concat(c.first_name, ' ', c.last_name) as candidate_name
    , oau.username as email
    , cg.gender_label
    , ce.ethnicity_label
    , l.name as location_name
    , l.country_code as country_code
    , c.accomplishment
    , lu.username as linkedin_username
    , c.linkedin_profile
    , c.created as candidate_created
from calibers as c
left join candidate_gender cg ON c.id = cg.candidate_id
left join candidate_ethnicity ce ON c.id = ce.candidate_id
left join locations l ON c.location_id = l.id
left join oauth_users oau ON c.id = oau.id
left join linkedin_usernames lu ON c.id = lu.caliber_id
left join candidate_events cev ON cev.caliber_id = c.id
inner join positions ON cev.position_id = positions.id
where 1=1 
    [[and {{position_id}}]]
    [[and {{company_id}}]]
    [[and c.created between {{start_date}} and {{end_date}}]]
group by c.id;
