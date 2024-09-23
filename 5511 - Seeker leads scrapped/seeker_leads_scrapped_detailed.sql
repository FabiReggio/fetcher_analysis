-- Seeker leads scrapped [Detailed] --

SELECT 
    c.id as seeker_id
    , concat(c.first_name, ' ', c.last_name) as seeker_name
    , oa.username as seeker_email
    , ct.created as created
    , case 
      when country_code='VEN' 
        then CONVERT_TZ (ct.created, '+00:00', '-04:00') 
      when country_code='COL'
        then CONVERT_TZ (ct.created, '+00:00', '-05:00') 
      else 
        CONVERT_TZ (ct.created, '+00:00', tz.offset)
     end as created_localtime
    , ct.candidate_id
    , ct.position_id
    , case 
      when p.outreach_type=0
        then 'Fetcher Search'
      when p.outreach_type=1
        then 'Campaign' 
     end as search_type
FROM candidate_tracking ct
LEFT JOIN calibers c ON ct.scout_id = c.id 
LEFT JOIN oauth_users oa ON oa.id = c.id
LEFT JOIN positions p on p.id = ct.position_id
LEFT JOIN locations l on l.id = c.location_id
LEFT JOIN timezones tz on tz.id = l.timezone_id
WHERE 1=1
[[AND c.id = {{seeker_id}} ]]
[[AND oa.username = {{email}} ]]
[[AND DATE(ct.created) >= {{from}} ]]
[[AND DATE(ct.created) < {{until}} ]]
ORDER BY ct.created DESC;