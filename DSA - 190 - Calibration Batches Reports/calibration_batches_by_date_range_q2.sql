-- Q2: Calibration batches by date range

SELECT * 
    FROM (
        SELECT 
            c.id AS company_id
            , c.name AS company_name
            , p.name AS position_name
            , p.id AS position_id
            , COUNT(DISTINCT bc.caliber_id) AS leads
            , SUM(CASE WHEN bc.liked = 1 THEN 1 ELSE 0 END) AS likes
            , SUM(CASE WHEN bc.liked = 2 THEN 1 ELSE 0 END) AS dislikes
            , COUNT(fb.id) AS feedbacks
            , SUM(CASE WHEN bc.liked = 0 THEN 1 ELSE 0 END) AS unvetted
            , SUM(CASE WHEN bc.liked = 0 THEN 1 ELSE 0 END) / COUNT(DISTINCT bc.caliber_id) AS unvetted_rate
            , concat('https://admin.fetcher.ai/positions/', p.id) AS admin_link
            , concat(p_owner.first_name, ' ', p_owner.last_name) AS position_owner
            , oau.username AS owner_email
            , p.created AS position_created
        FROM positions p 
        LEFT JOIN companies c ON p.company_id = c.id
        LEFT JOIN positions_batches pb ON pb.position_id = p.id
        LEFT JOIN batches b ON b.id = pb.batch_id
        LEFT JOIN customer_companies cc ON cc.company_id = c.id 
        LEFT JOIN positions_side_owners pso ON
                pso.caliber_id = cc.caliber_id
                AND pso.position_id = p.id
                AND pso.is_owner = 1
        LEFT JOIN calibers AS p_owner ON p_owner.id = pso.caliber_id
        LEFT JOIN oauth_users oau ON oau.id = p_owner.id
        LEFT JOIN batch_candidates bc ON bc.batch_id = b.id
        LEFT JOIN candidates_feedback AS fb ON fb.caliber_id = bc.caliber_id AND fb.position_id = p.id
        WHERE 1=1
            AND pso.position_id IS NOT NULL
            AND b.status = 2
            [[AND c.id = {{company_id}}]]
            [[AND p.created BETWEEN {{start_date}} AND {{end_date}}]] 
        GROUP by 
            p.id
            , b.id
        ORDER BY 
            p.id DESC 
    ) AS temp
GROUP BY 
    temp.position_id
ORDER BY
    temp.position_created DESC; 