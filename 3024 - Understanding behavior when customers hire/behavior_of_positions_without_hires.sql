SELECT 
    temp.pos_without_hire as "# Positions without hires",
    (sum(temp.likes) - sum(temp.undo_likes)) / sum(temp.total_leads) as likes_rate,
    (sum(temp.dislikes) - sum(undo_dislikes)) / sum(temp.total_leads) as dislikes_rate,
    sum(temp.emailed) / sum(temp.added_to_search) as email_rate,
    sum(temp.responded_bc) / sum(temp.emailed_bc) as response_rate,
    (sum(temp.interested) - sum(undo_interested)) / sum(temp.total_leads) as interest_rate,
    sum(temp.total_comments) / sum(temp.total_leads) as comments_rate
FROM (
    SELECT 
        (SELECT count (distinct (position_id))
        FROM candidate_events ce
        WHERE ce.position_id not in 
            (
                SELECT distinct (position_id)
                FROM candidate_events
                WHERE event_id in (405,412)
            )
        ) as pos_without_hire,
        sum(case when ce.event_id = 201 then 1 else 0 end) as likes,
        sum(case when ce.event_id = 203 then 1 else 0 end) as undo_likes,
        sum(case when ce.event_id = 202 then 1 else 0 end) as dislikes,
        sum(case when ce.event_id = 204 then 1 else 0 end) as undo_dislikes,
        sum(case when ce.event_id = 408 then 1 else 0 end) as interested,
	sum(case when ce.event_id = 409 then 1 else 0 end) as undo_interested,
        sum(case when ce.event_id in (1, 2) then 1 else 0 end) as emailed,
        sum(case when ce.event_id = 101 then 1 else 0 end) as added_to_search,
        count(distinct bc.caliber_id) as total_leads,
        -- BATCH CANDIDATES METRICS
        sum(bc.responded) as responded_bc,
        sum(case when bc.contact_status >= 1 then 1 else 0 end) as emailed_bc,
        -- COMMENTS METRICS
        count(distinct com.id) as total_comments
    FROM candidate_events ce
    LEFT JOIN batch_candidates AS bc ON ce.caliber_id = bc.caliber_id AND ce.batch_id = bc.batch_id  
    LEFT JOIN batches AS b ON  b.id = bc.batch_id
    LEFT JOIN comments AS com ON com.candidate_id = ce.caliber_id AND com.position_id = ce.position_id AND com.batch_id = ce.batch_id 
    WHERE 1=1
    AND b.status = 2
    AND ce.position_id not in 
        (
           SELECT distinct (position_id)
            FROM candidate_events
            WHERE 
                event_id in 
                (
                	405, -- Hired
                	412 -- Undo Hired
                )
        )
) temp;
