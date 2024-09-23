SELECT 
    count(*) as "# Total Responses",
    sum(CASE WHEN contact_status=1 THEN 1 ELSE 0 END) as "# 1st touchpoint",
    (sum(CASE WHEN contact_status=1 THEN 1 ELSE 0 END) / count(*))*100 as "% from 1st",
    sum(CASE WHEN contact_status=2 THEN 1 ELSE 0 END) as "# 2nd touchpoint",
    (sum(CASE WHEN contact_status=2 THEN 1 ELSE 0 END) / count(*))*100 as "% from 2nd",
    sum(CASE WHEN contact_status=3 THEN 1 ELSE 0 END) as "# 3rd touchpoint",
    (sum(CASE WHEN contact_status=3 THEN 1 ELSE 0 END) / count(*))*100 as "% from 3rd",
    sum(CASE WHEN contact_status=4 THEN 1 ELSE 0 END) as "# 4th touchpoint",
    (sum(CASE WHEN contact_status=4 THEN 1 ELSE 0 END) / count(*))*100 as "% from 4th",
    sum(CASE WHEN contact_status=5 THEN 1 ELSE 0 END) as "# 5th touchpoint",
    (sum(CASE WHEN contact_status=5 THEN 1 ELSE 0 END) / count(*))*100 as "% from 5th",
    sum(CASE WHEN contact_status=6 THEN 1 ELSE 0 END) as "# 6th touchpoint",
    (sum(CASE WHEN contact_status=6 THEN 1 ELSE 0 END) / count(*))*100 as "% from 6th"
FROM batch_candidates bc
    LEFT JOIN positions_batches pb ON pb.batch_id = bc.batch_id 
    LEFT JOIN positions p ON pb.position_id = p.id
    LEFT JOIN companies co ON p.company_id = co.id
WHERE bc.responded=1 -- Candidates responded
    [[AND co.name={{company}}]];