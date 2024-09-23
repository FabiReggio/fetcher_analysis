SELECT
    cal.id as `Candidate ID`
    , cal.first_name as `Candidate First Name`
    , cal.last_name as `Candidate Last Name`
    , comp.id as `Candidate's company ID`
    , comp.name as `Candidate's company`
    , max(cc.start_date) as start_date
    , cc.end_date
    , CASE
        WHEN bc.contact_status > 0 THEN 'Yes'
        ELSE 'No'
    END as `Contacted`
    , CASE
        WHEN bc.liked = 1 THEN 'Liked'
        WHEN bc.liked = 2 THEN 'Disliked'
        ELSE 'None'
    END as `Feedback`
    , pb.position_id as `Position`
    , pos_comp.name as `Position Company`
    , pos_comp.id as `Position Company ID`
    , bc.batch_id as `Batch`
    , p.name as 'Position Name'
    , cal.linkedin_profile as `LinkedIn`
    , oa.username as `Email`
    , concat('http://admin.fetcher.ai/positions/',pb.position_id,'/',bc.batch_id) as `URL`
    , concat('https://stats.fetcher.ai/question/76?pid=',pb.position_id,'&candidate_id=',bc.caliber_id) as events
    , bc.created
    , bc.contact_date as last_contact_date
FROM batch_candidates bc
JOIN positions_batches pb on pb.batch_id = bc.batch_id
JOIN positions p on pb.position_id = p.id
JOIN companies pos_comp on p.company_id = pos_comp.id
JOIN calibers cal on cal.id = bc.caliber_id
JOIN oauth_users oa on oa.id = cal.id
left join caliber_companies as cc on
    cc.caliber_id = bc.caliber_id
left join companies as comp on comp.id = cc.company_id
WHERE 1=1
    [[and p.id = {{position}}]]
    [[and p.company_id = {{company_id}}]]
    [[and cal.first_name regexp {{first_name}}]]
    [[and cal.last_name regexp {{last_name}}]]
    [[and lower(pos_comp.name) regexp lower({{company}})]]
group by
    cal.id 
    , pb.position_id
    , bc.batch_id
    , pos_comp.id
LIMIT 2000