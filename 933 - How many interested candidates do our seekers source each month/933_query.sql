SELECT
    t.id AS "Scout_ID", t.first_name AS "First Name", t.last_name AS "Last Name", count(t.candidate_id) "# of interested candidates", DATE_FORMAT(t.created, "%m/%Y") as "Month"
FROM
(
    SELECT c.id, c.first_name, c.last_name, ct.candidate_id, ct.created
    FROM calibers c
    JOIN candidate_tracking ct ON ct.scout_id = c.id -- The id of the scout
    JOIN candidate_events ce ON ce.caliber_id = ct.candidate_id  -- MATCH BETWEEN candidate_events and candidate_tracking through the candidate 
    JOIN candidate_event_types cet ON cet.id = ce.event_id -- MATCH BETWEEN candidate_events and candidate_event_types
    WHERE c.user_type = 1 -- Aggregating condition when the caliber is a customer
    AND cet.id = 408 -- Status: Interested. When a candidate is interested
) as t

[[WHERE t.id =  {{scout_id}}]] 

GROUP BY t.id, t.first_name, t.last_name, DATE_FORMAT(t.created, "%m/%Y")
ORDER BY DATE_FORMAT(t.created, "%Y%m"), count(t.candidate_id) DESC;