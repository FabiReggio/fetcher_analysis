SELECT 
    co.id as "Company Id",
    co.name as "Company Name",
    case 
        when co.status = 0 then 'Not Customer' 
        when co.status = 1 then 'Active' 
        when co.status = 2 then 'Canceled' 
    end as "Company Status",
     case 
        when co.status = 1 then TIMESTAMPDIFF(MONTH,min(pso.created), CURDATE()) 
        when co.status = 2 then TIMESTAMPDIFF(MONTH,min(pso.created), max(pso.created))
    end as "# Months Active with Fetcher",
    count(*) as "# Total of Emails Sent",
    sum(CASE WHEN ce.email_sender=0 THEN 1 ELSE 0 END) as "# of Emails Sent with Sendgrid",
    concat(format((sum(CASE WHEN ce.email_sender=0 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Emails Sent with Sendgrid",
    sum(CASE WHEN ce.email_sender=1 THEN 1 ELSE 0 END) as "# of Emails Sent with Gmail",
    concat(format((sum(CASE WHEN ce.email_sender=1 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Emails Sent with Gmail",
    sum(CASE WHEN ce.email_sender=2 THEN 1 ELSE 0 END) as "# of Emails Sent with Outlook",
    concat(format((sum(CASE WHEN ce.email_sender=2 THEN 1 ELSE 0 END)/count(*))*100,0),"%") as "% of Emails Sent with Outlook",
    concat(format((sum(case when cis.status=1 then 1 else 0 end)/ sum(case when bc.responded=1 then 1 else 0 end))*100,0),"%") as "% Interested",
    concat(format((sum(case when bc.responded=1 then 1 else 0 end)/ sum(case when bc.contact_status>0 then 1 else 0 end) )*100,0),"%") as "% Responded"
FROM candidate_message ce 
LEFT JOIN customer_companies AS cc ON cc.caliber_id = ce.from_id 
LEFT JOIN companies AS co ON co.id = cc.company_id
-- BATCHES AND POSITIONS DATA 
LEFT JOIN positions_side_owners as pso on pso.caliber_id = cc.caliber_id and pso.is_owner = 1
LEFT JOIN positions_batches pb ON pso.position_id = pb.position_id 
LEFT JOIN batch_candidates bc ON bc.batch_id = pb.batch_id 
LEFT JOIN batches b on b.id = bc.batch_id 
-- INTERESTED CANDIDATES DATA
LEFT JOIN candidate_interested_status cis ON cis.candidate_id = bc.caliber_id AND cis.position_id = pso.position_id 
WHERE 1=1
    [[AND co.id = {{company_id}}]]
    [[AND co.name = {{company_name}}]]
    AND b.status = 2 -- BATCH STATUS: SENT
GROUP BY co.id;