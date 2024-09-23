SELECT 
co.id as "Company Id",
co.name as "Company Name",
(managed_leads_paid - managed_leads_used) as "Fetcher Leads Remaining",
(self_served_leads_paid - self_served_leads_used) as "Extension Leads Remaining",
case 
    when c.status = 1 then TIMESTAMPDIFF(DAY,c.start_date,CURDATE())
    when c.status = 2 then "Company Revoked"
    when c.status = 3 then "Contract Inactive"
end as "# Days Used On Contract",
case 
    when c.status = 1 then TIMESTAMPDIFF(DAY,CURDATE(),ifnull(date_add(DATE_SUB(c.end_date, INTERVAL 1 DAY), interval addon.amount day), DATE_SUB(c.end_date, INTERVAL 1 DAY)))
    when c.status = 2 then "Company Revoked"
    when c.status = 3 then "Contract Inactive"
end as "# Days Left On Contract",
case 
    when c.status = 1 then concat(format((TIMESTAMPDIFF(DAY,c.start_date,CURDATE()) / TIMESTAMPDIFF(DAY,c.start_date,ifnull(date_add(DATE_SUB(c.end_date, INTERVAL 1 DAY), interval addon.amount day), DATE_SUB(c.end_date, INTERVAL 1 DAY))))*100,0),"%")
    when c.status = 2 then "Company Revoked"
    when c.status = 3 then "Contract Inactive"
end as "% of Contract Completed",
case 
    when c.status = 1 then concat(format((TIMESTAMPDIFF(DAY,CURDATE(),ifnull(date_add(DATE_SUB(c.end_date, INTERVAL 1 DAY), interval addon.amount day), DATE_SUB(c.end_date, INTERVAL 1 DAY))) / TIMESTAMPDIFF(DAY,c.start_date,ifnull(date_add(DATE_SUB(c.end_date, INTERVAL 1 DAY), interval addon.amount day), DATE_SUB(c.end_date, INTERVAL 1 DAY))))*100,0),"%")
    when c.status = 2 then "Company Revoked"
    when c.status = 3 then "Contract Inactive"
end as "% of Contract To Complete"
FROM contract_trackings ct
LEFT JOIN contracts c ON c.id = ct.contract_id -- MATCH BETWEEN contracts and contracts_trackings 
LEFT JOIN companies co ON co.id = c.company_id -- MATCH BETWEEN contracts and companies
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
WHERE 1=1
AND c.status not in (0,4) -- Excluding expired and canceled contracts
[[AND co.id = {{company_id}}]]
[[AND co.name = {{company_name}}]]
ORDER BY (managed_leads_paid - managed_leads_used) desc; 