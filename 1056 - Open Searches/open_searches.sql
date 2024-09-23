SELECT 
    DISTINCT
    positions.id AS "PositionId",
    positions.name AS "Position",
    CASE
        WHEN positions.status = 1
               THEN "New"
               ELSE "Open"
       END as "Status",
    DATE(positions.created) AS "Created",
    companies.name AS "Company",
    owner_company.name AS "Owner Company",
    CONCAT(calibers.first_name,' ',calibers.last_name) AS "Owner",
    oauth_users.username AS "Owner email",
    CONCAT(scouts_admins.first_name,' ',scouts_admins.last_name) AS "Team Lead",
    CONCAT('https://admin.fetcher.ai/positions/',positions.id) AS "Link",
       (SELECT count(bc.id) 
        FROM batch_candidates bc
        LEFT JOIN positions_batches pb ON pb.batch_id = bc.batch_id
        LEFT JOIN batches b ON b.id = pb.batch_id
        -- Only sent batches
        WHERE b.status = 2
        AND pb.position_id = positions.id
    ) AS "Leads sent",
       (SELECT count(bc.id) 
        FROM batch_candidates bc
        LEFT JOIN positions_batches pb ON pb.batch_id = bc.batch_id
        LEFT JOIN batches b ON b.id = pb.batch_id
        -- Only sent batches
        WHERE b.status = 2
        AND pb.position_id = positions.id
        AND bc.liked = 1
    ) AS "Likes"
FROM positions
    -- Access the company ID of the position name in the search
    LEFT JOIN companies ON companies.id=positions.company_id
    LEFT JOIN positions_side_owners ON positions_side_owners.position_id = positions.id AND positions_side_owners.is_owner = 1
    LEFT JOIN customer_companies ON positions_side_owners.caliber_id = customer_companies.caliber_id
    -- Access the company ID for the position owner
    LEFT JOIN companies owner_company ON owner_company.id=customer_companies.company_id
    LEFT JOIN position_members ON position_members.position_id = positions.id
    LEFT JOIN scouts_admins ON scouts_admins.scout_id = position_members.caliber_id
    LEFT JOIN calibers ON calibers.id = positions_side_owners.caliber_id
    LEFT JOIN oauth_users ON oauth_users.id = customer_companies.caliber_id
WHERE 1 = 1
    -- Grab only open positions
    AND positions.status <= 2
    -- Exclude Fetcher & Sample Searches
    AND NOT companies.name = 'Fetcher' 
    AND positions.name NOT like '%SAMPLE%' 
    -- Grab Team Lead
    AND position_members.role_id = 2
    -- Excludes Exention Searches
    AND positions.operation_mode = 0
    -- Set a default value with the current date minus 1 day, the optional variable will comment the current_date function
    AND DATE(positions.created) >= [[ {{date_created}} #]]DATE_SUB(CURDATE(), INTERVAL 1 DAY)
    [[AND companies.id = {{company_id}}]]
    [[AND companies.name = {{company_name}}]]
    