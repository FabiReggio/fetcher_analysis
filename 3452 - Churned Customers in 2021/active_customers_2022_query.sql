SELECT
    co.id as "Company Id",
    co.name as "Company Name"
FROM contracts c
LEFT JOIN customer_companies as cc on c.company_id = cc.company_id 
LEFT JOIN companies co ON c.company_id = co.id 
WHERE 1=1
AND c.status = 1 -- CONTRACT STATUS: Active
    [[AND co.id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
GROUP BY co.id; 
