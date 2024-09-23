SELECT 
    p.id as "Position ID",
    p.name as "Position Name",
    ce.caliber_id as "Caliber ID",
    date(p.created) as "Position Created",
    
    -- EVENTS DATES
    date(min(case when ce.event_id=101 then ce.created else null end)) as added_to_search_date,
    date(min(case when ce.event_id=3 then ce.created else null end)) as email_scheduled_date,
    date(min(case when ce.event_id in (1, 2) then ce.created else null end)) as first_email_sent_date,
    date(min(case when ce.event_id=14 then ce.created else null end)) as replied_date,
    date(min(case when ce.event_id=408 then ce.created else null end)) as interested_date,
    date(min(case when ce.event_id=405 then ce.created else null end)) as hired_date,
    
    -- ADDITIONAL METRICS SINCE POSITION IS CREATED
    DATEDIFF (min(case when ce.event_id=101 then ce.created else null end), p.created) as "Days to Source",
    DATEDIFF (min(case when ce.event_id=3 then ce.created else null end), p.created) as "Days to Schedule Email",
    DATEDIFF (min(case when ce.event_id in (1, 2) then ce.created else null end), p.created) as "Days to Contact",
    DATEDIFF (min(case when ce.event_id=14 then ce.created else null end), p.created) as "Days to Respond",
    DATEDIFF (min(case when ce.event_id=408 then ce.created else null end), p.created) as "Days to be Interested",
    DATEDIFF (min(case when ce.event_id=405 then ce.created else null end), p.created) as "Days to be Hired"
    
    /* 
    -- METRICS SINCE POSITION IS ADDED TO SEARCH
    DATEDIFF (min(case when ce.event_id in (1, 2) then ce.created else null end), min(case when ce.event_id=101 then ce.created else null end)) as "Days to contact since Added to Search",
    DATEDIFF (min(case when ce.event_id=405 then ce.created else null end),min(case when ce.event_id=101 then ce.created else null end)) as "Days to contract since Added to Search",
    
    -- OUTSIDE FETCHER METRICS
    date(min(case when ce.event_id=401 then ce.created else null end)) as "Contacted outside Fetcher",
    date(min(case when ce.event_id=406 then ce.created else null end)) as "Responded outside Fetcher"
    */
    
FROM candidate_events ce
LEFT JOIN positions p ON ce.position_id = p.id
WHERE 1=1
    -- (POSITIONS,CANDIDATES) WITH HIRES
    AND (ce.position_id,ce.caliber_id) in
            (SELECT position_id, caliber_id
            FROM candidate_events 
            WHERE event_id= 405 -- Hired
            GROUP BY position_id)
    [[AND ce.position_id = {{position_id}}]]
GROUP BY ce.position_id, ce.caliber_id -- Grouped By: Position ID, Caliber ID
ORDER BY ce.position_id desc; -- Ordered by Most Recent Position 
