SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    case 
        when co.status = 0 then 'Not Customer' 
        when co.status = 1 then 'Active' 
        when co.status = 2 then 'Canceled' 
    end as "Company Status", 
    count(*) as "# Total of Customers",
    sum(CASE WHEN c.email_sender=0 THEN 1 ELSE 0 END) as "# of Customers with Sendgrid",
    concat(format((sum(CASE WHEN c.email_sender=0 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Customers with Sendgrid",
    sum(CASE WHEN c.email_sender=1 THEN 1 ELSE 0 END) as "# of Customers with Gmail",
    concat(format((sum(CASE WHEN c.email_sender=1 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Customers with Gmail",
    sum(CASE WHEN c.email_sender=2 THEN 1 ELSE 0 END) as "# of Customers with Outlook",
    concat(format((sum(CASE WHEN c.email_sender=2 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Customers with Outlook"
FROM calibers c
-- TOKEN FOR GOOGLE
LEFT JOIN google_access_tokens gat ON gat.caliber_id = c.id
-- TOKEN FOR OUTLOOK
LEFT JOIN outlook_access_tokens oat ON oat.caliber_id = c.id
-- CUSTOMER COMPANIES
LEFT JOIN customer_companies as cc ON cc.caliber_id = c.id
LEFT JOIN companies as co ON cc.company_id = co.id 
WHERE 1=1
    AND c.user_type = 1 -- Customers
    [[AND co.id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]; 
