-- Seeker leads scrapped [Grouped by Seeker] --

SELECT 
    c.id as seeker_id
    , concat(c.first_name, ' ', c.last_name) as seeker_name
    , oa.username as seeker_email
    , sum(case when p.outreach_type=0 then 1 else 0 end) as fetcher_search
    , sum(case when p.outreach_type=1 then 1 else 0 end) as campaign_search
FROM candidate_tracking ct
LEFT JOIN calibers c ON ct.scout_id = c.id 
LEFT JOIN oauth_users oa ON oa.id = c.id
LEFT JOIN positions p on p.id = ct.position_id
WHERE 1=1
[[AND c.id = {{seeker_id}} ]]
[[AND oa.username = {{email}} ]]
[[AND DATE(ct.created) >= {{from}} ]]
[[AND DATE(ct.created) < {{until}} ]]
GROUP BY c.id -- GROUP BY SEEKER ID
ORDER BY sum(case when p.outreach_type=0 then 1 else 0 end) DESC; -- ORDER DESC BY FETCHER SEARCH