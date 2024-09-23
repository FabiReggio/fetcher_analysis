SELECT temp.c_name as 'company',
       -- temp.id as 'position_id', 
       count(temp.p_name) as 'positions',
       sum(IF((temp.fetcher_leads - temp.ext_leads - temp.copied_leads)>0,(temp.fetcher_leads - temp.ext_leads - temp.copied_leads),0)) as 'fetcher_leads', 
       sum(temp.copied_leads) as 'copied_leads',
       sum(temp.ext_leads) as 'ext_leads',
       sum(temp.fetcher_leads) as total_leads,
       sum(temp.emailed) as Emailed,
       concat(format(sum(temp.emailed)/sum(temp.fetcher_leads)*100,1),"%") as email_rate,
       sum(temp.responded) as Responded,
       concat(format(sum(temp.responded)/sum(temp.emailed)*100,1),"%") as response_rate,
       sum(temp.interested) as Interested,
       concat(format(sum(temp.interested)/sum(temp.responded)*100,1),"%") as interested_rate

FROM 
    (SELECT c.NAME as 'c_name', 
       p.id, 
       concat(u.first_name,' ',u.last_name) as owner,
       p.NAME as 'p_name', 
       (SELECT Count(*) 
        FROM   batch_candidates bc 
               JOIN positions_batches pb 
                 ON pb.batch_id = bc.batch_id 
               JOIN batches b 
                 ON pb.batch_id = b.id 
               JOIN candidate_events ce
                 ON ce.batch_id = b.id and ce.position_id = pb.position_id and bc.caliber_id = ce.caliber_id -- and (ce.event_id = 101 OR ce.event_id = 114) 
        WHERE  b.status = 2 
               AND pb.position_id = p.id
               and (ce.event_id = 101 OR ce.event_id = 114) 
               [[and date(ce.created) between {{start_date}} and {{end_date}}]]) AS 'fetcher_leads', 
       
       -- copied leads 
       (SELECT Count(*) 
        FROM   batch_candidates bc 
               JOIN positions_batches pb 
                 ON pb.batch_id = bc.batch_id 
               JOIN batches b 
                 ON pb.batch_id = b.id
               JOIN candidate_events ce
                 ON ce.position_id = pb.position_id and ce.caliber_id = bc.caliber_id
        WHERE  b.status = 2 
                AND b.type = 2
               AND pb.position_id = p.id
               AND ce.event_id = 111
               [[and date(ce.created) between {{start_date}} and {{end_date}}]]) AS 'copied_leads', 


       -- Extension leads
           (SELECT Count(*) 
            FROM imported_candidates ic 
            JOIN linkedin_usernames lu ON lu.username = ic.linkedin_username
            JOIN candidate_events ce ON ce.position_id = ic.position_id AND ce.caliber_id = lu.caliber_id
            WHERE  ic.status = 1 
                   AND ic.position_id = p.id
                   AND (ce.event_id = 101 OR ce.event_id = 114)
                   [[and date(ce.created) between {{start_date}} and {{end_date}}]]) AS 'ext_leads',

        
        -- Emailed
        (select 
            count(distinct ce.caliber_id) 
        from 
            candidate_events ce
        where 
            ce.position_id=p.id and ce.event_id in (1,2) 
            [[and date(ce.created) between {{start_date}} and {{end_date}}]] ) as emailed,
        
        -- replies
        (select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (14) [[and date(ce.created) between {{start_date}} and {{end_date}}]] ) as responded,

        -- interested
        (select count(distinct ce.caliber_id) from candidate_events ce where ce.position_id=p.id and ce.event_id in (408) [[and date(ce.created) between {{start_date}} and {{end_date}}]] ) as interested
            
FROM   companies c 
       JOIN customer_companies cc 
         ON cc.company_id = c.id 
       JOIN positions_side_owners pso 
         ON cc.caliber_id = pso.caliber_id 
       JOIN positions p 
         ON pso.position_id = p.id
        JOIN calibers u on pso.caliber_id = u.id 
WHERE  /* ( cc.status <> 4  // we need to see activity for cancelled ppl
         AND cc.status <> 3 ) 
       AND */
       pso.is_owner = 1 
[[AND c.name regexp {{company_name}}]]
ORDER  BY 1 ASC, 
          3 ASC) temp
WHERE 
(temp.fetcher_leads > 0 
OR temp.copied_leads > 0
OR temp.ext_leads > 0
OR temp.emailed > 0
OR temp.responded > 0
OR temp.interested > 0)

group by
    temp.c_name
;