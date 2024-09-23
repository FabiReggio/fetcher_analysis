select 
    temp.search_id
    , temp.search_name
    , temp.date_added
    , temp.candidate_id
    , temp.candidate_name 
    , temp.candidate_email
    , temp.self_sourced
    , group_concat(temp.location order by temp.location asc separator '; ') as location_list
    , temp.candidate_linkedin
from (
    select 
        p.id as search_id
        , p.name as search_name
        , ceven.created as date_added
        , c.id as candidate_id
        , concat(c.first_name, " ", c.last_name) as candidate_name
        , ce.email as candidate_email
        , if(
            (
                select 
                    count(*)
                from imported_candidates ic
                where ic.linkedin_username = lu.username 
                    and ic.position_id = p.id 
                    and ic.status = 1
            )
            > 0, "yes","no") as self_sourced
        ,@country:= (
            select 
                name
            from locations loc
            where loc.id = SUBSTRING_INDEX(l.full_id, '-', 1) 
        ) as country
        ,@state:= (
            select 
                name
            from locations loc
            where loc.id = SUBSTRING_INDEX(SUBSTRING_INDEX(l.full_id,'-', 2), '-',-1)
        ) as state
       ,@city:= (
            select 
                name
            from locations loc
            where loc.id = SUBSTRING_INDEX(l.full_id, '-', -1) 
        ) as city
        , @location:= concat(@country, ", " , @state, ", " , @city) as location
        , c.linkedin_profile as candidate_linkedin
    from batch_candidates bc
        join positions_batches pb on pb.batch_id = bc.batch_id
        join positions p on p.id = pb.position_id
        join batches b on pb.batch_id = b.id 
        join calibers c on bc.caliber_id = c.id
        join companies co on p.company_id = co.id
        join linkedin_usernames lu on c.id = lu.caliber_id
        join position_candidate_emails pce on pce.position_id = p.id and pce.candidate_id = c.id
        join candidate_emails ce on ce.id = pce.candidate_email_id
        join candidate_events ceven on ceven.position_id = p.id and ceven.caliber_id = c.id
        left outer join positions_locations pl on pl.position_id = p.id
        left outer join locations l on l.id = pl.location_id
    where b.status = 2
        -- added to search or self sourced event
        and ceven.event_id in (100, 101, 114, 111) 
        [[and p.id = {{position}}]]
        [[and lower(co.name) regexp lower({{company}})]]
        [[and date(b.modified) between {{start_date}} and {{end_date}}]]
    order by search_id, candidate_id
) as temp
group by 
    temp.search_id
    , temp.candidate_id
order by 
    search_id
    , candidate_id;