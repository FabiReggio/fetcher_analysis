SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    concat(ca.first_name," ", ca.last_name) as "Customer Name",
    oau.username as "Email Address",
    c.start_date as "Contract Start Date", 
    ifnull(date_add(c.end_date, interval addon.amount day), c.end_date) as 'Contract End date'
FROM contracts c
-- CONTRACT END DATE ADD ON CORRECTION
    LEFT JOIN (
        select
            cdao.contract_id,
            sum(dao.amount) as amount
        from contract_duration_add_ons as cdao
        left join duration_add_ons as dao on dao.id = cdao.duration_add_on_id
        group by
            cdao.contract_id
    ) as addon on addon.contract_id = c.id 
LEFT JOIN customer_companies as cc on c.company_id = cc.company_id 
LEFT JOIN companies co ON c.company_id = co.id 
LEFT JOIN calibers ca ON cc.caliber_id = ca.id -- JOIN TO GET ALL MEMBERS FOR EACH COMPANY
LEFT JOIN oauth_users oau ON oau.id = ca.id
WHERE 1=1 
    -- SELECT COMPANIES WITHOUT ACTIVE CONTRACTS
    AND co.id NOT IN 
        (
            SELECT c.company_id
            FROM contracts c
            -- CONTRACT STATUS: Active
            WHERE c.status = 1
        )
    AND c.status = 0 -- Contract Status: Expired
    AND YEAR(ifnull(date_add(c.end_date, interval addon.amount day), c.end_date)) = 2021
    [[AND co.id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
GROUP BY co.id, ca.id, c.id;
