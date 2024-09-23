SELECT *
FROM (
    SELECT  
        c.name AS company
        , CONCAT(oa.first_name, ' ',  oa.last_name) AS user_name
        , oa.username AS email
        , oa.last_login_datetime
        , case 
            when cc.status = 0 then 'MEMBER'
            when cc.status = 1 then 'INVITED'
            when cc.status = 2 then 'SIGNED UP'
            when cc.status = 3 then 'DEACTIVATED'
            when cc.status = 4 then 'SERVICE CANCELED'
        end as user_status
        , SUM(IF(p.status <= 2, 1, 0)) AS open_positions -- 1 and 2 open and new status
        , SUM(IF(p.status = 4, 1, 0)) AS hold_positions
        , SUM(IF(p.status = 3, 1, 0)) AS closed_positions
    FROM oauth_users oa
        JOIN  positions_side_owners pso ON pso.caliber_id = oa.id AND pso.is_owner = 1
        JOIN customer_companies cc ON cc.caliber_id = pso.caliber_id
        JOIN companies c ON c.id = cc.company_id
        JOIN positions p ON p.id = pso.position_id
    WHERE 1=1
        AND p.type = 0
        [[AND {{company_id}} = c.id]]
        [[AND lower({{company_name}}) = lower(c.name)]]
        -- AND p.outreach_type = 0 -- campaigns excluded
    GROUP BY
        c.name
        , concat(oa.first_name, ' ',  oa.last_name) 
        , oa.username
        , oa.last_login_datetime
) temp    
WHERE 1=1
    [[AND lower({{user_status}}) = lower(user_status)]]