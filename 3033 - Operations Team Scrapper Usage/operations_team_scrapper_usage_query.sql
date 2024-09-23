SELECT 
    ct.scout_id as "Seeker ID",
    concat(seekers.first_name, ' ', seekers.last_name) as "Seeker Name",
    tl.caliber_id as "Team Lead ID",
    concat(tl_info.first_name, ' ', tl_info.last_name) as "Team Lead Name",
    min(ct.created) as "Time of the day the seeker started using the scrapper",
    max(ct.created) as "Time of the day the seeker last used used the scrapper",
    TIMESTAMPDIFF(MINUTE, min(ct.created), max(ct.created)) as "Time the specialist uses the scrapper per day (Minutes)",
    TIMESTAMPDIFF(HOUR, min(ct.created), max(ct.created)) as "Time the specialist uses the scrapper per day (Hours)"
FROM candidate_tracking ct
-- SEEKER INFO
LEFT JOIN position_members as pm ON 
    pm.caliber_id = ct.scout_id 
    AND ct.position_id = pm.position_id
LEFT JOIN calibers as seekers on seekers.id = pm.caliber_id -- Seeker Info
-- TEAM LEADER INFO
LEFT JOIN position_members as tl ON -- info about who the Team leader is
	tl.position_id = ct.position_id
	AND tl.role_id = 2 -- Team Leader role
LEFT JOIN calibers as tl_info on tl_info.id = tl.caliber_id -- Team Leader Info
WHERE 1=1
    AND pm.role_id = 1 -- Seeker Role
    [[AND ct.scout_id = {{seeker_id}}]]
    [[AND concat(seekers.first_name, ' ', seekers.last_name) regexp {{seeker_name}}]]
    [[AND tl.caliber_id = {{tl_id}}]]
	[[AND concat(tl_info.first_name, ' ', tl_info.last_name) regexp {{team_leader}}]]
	[[AND pm.position_id = {{position_id}}]]
GROUP BY 
    ct.scout_id, DATE(ct.created) -- GROUP BY SEEKER,CREATED
ORDER BY 
    ct.scout_id,DATE(ct.created) DESC;

    