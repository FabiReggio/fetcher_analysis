SELECT 
    company_id as "Company Id",
    company_name as "Company Name",
    sum(num_active_team_members) as "# of Active Team Members",
    sum(num_admins) as "# of Admins",
    sum(num_watchers_1) as "# of Watchers",
    seats_used as "# of Seats Used",
    seats_paid as "# of Seats Paid"
FROM (
    SELECT 
        co.id as company_id,     
        co.name as company_name, 
        count(distinct ca.id) as num_active_team_members,
        sum(distinct CASE WHEN cc.is_admin=1 THEN 1 ELSE 0 END) as num_admins,
        sum(distinct CASE WHEN pso.is_owner=0 THEN 1 ELSE 0 END) as num_watchers_1,
        seats_paid,
        seats_used
    FROM customer_companies cc
    LEFT JOIN companies co ON cc.company_id = co.id 
    LEFT JOIN calibers ca ON cc.caliber_id = ca.id 
    LEFT JOIN positions_side_owners AS pso ON pso.caliber_id = cc.caliber_id AND pso.is_owner = 0 -- WATCHERS
    -- JOINS TO GET SEATS METRICS 
    LEFT JOIN contracts AS c ON c.company_id = co.id 
    LEFT JOIN contract_trackings AS ct ON ct.contract_id = c.id
    WHERE 1=1
        AND co.status = 1 -- Company Status: Active
        AND cc.status = 2 -- MEMBER_STATUS_SIGNED_UP
        [[AND co.id = {{company_id}}]]
        [[AND co.name = {{company_name}}]]
    GROUP BY cc.company_id, ca.id
) q1
GROUP BY q1.company_id
ORDER BY sum(num_active_team_members) desc;