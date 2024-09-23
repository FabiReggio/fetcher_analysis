-- Lag time between when the first email is sent and the first response based on the time of the day the email was sent --

SELECT 
    hour(temp_2.first_email_sent_date) AS hour_first_email_sent
    , AVG(temp_2.days_from_contact_to_respond) AS avg_days_from_contact_to_respond
    , AVG(temp_2.hours_from_contact_to_respond) AS avg_hours_from_contact_to_respond
FROM(
        SELECT 
            temp.position_id
            , temp.position_name
            , temp.caliber_id
            , temp.first_email_sent_date
            , temp.replied_date
            , temp.days_from_contact_to_respond
            , temp.hours_from_contact_to_respond
        FROM (
            SELECT 
                p.id as position_id
                , p.name as position_name
                , ce.caliber_id as caliber_id
                , min(case when ce.event_id in (1, 2) then ce.created else null end) as first_email_sent_date
                , min(case when ce.event_id=14 then ce.created else null end) as replied_date
                , DATEDIFF (min(case when ce.event_id=14 then ce.created else null end), min(case when ce.event_id in (1, 2) then ce.created else null end)) as days_from_contact_to_respond
                , TIMESTAMPDIFF(HOUR, min(case when ce.event_id in (1, 2) then ce.created else null end), min(case when ce.event_id=14 then ce.created else null end)) as hours_from_contact_to_respond
            FROM candidate_events ce
            LEFT JOIN positions p ON ce.position_id = p.id 
            WHERE 1=1
                AND ce.event_id in (
                1, -- Email Sent
                2, -- Email Sent
                14 -- Replied
                )
                AND year(ce.created) >= 2020
            GROUP BY ce.position_id, ce.caliber_id -- Grouped By: Position ID, Caliber ID
            ORDER BY ce.position_id desc -- Ordered by Most Recent Position 
        ) as temp
            where 1=1
            and temp.first_email_sent_date != '0000-00-00 00:00:00'
            and temp.replied_date != '0000-00-00 00:00:00'
    ) as temp_2
GROUP BY hour(temp_2.first_email_sent_date) 
ORDER BY hour(temp_2.first_email_sent_date) asc; 
 

