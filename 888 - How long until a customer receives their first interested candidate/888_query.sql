SELECT 
    ca.first_name as "First Name",
    ca.last_name as "Last Name",
    co.name as "Company Name",
    ca.created as "Customer Created Date",
    TIMESTAMPDIFF(DAY,ca.created, b.modified) AS "Time to get first interested candidate", -- Time batch was sent - Caliber created Time 
    co.employees as "Business Size"
FROM positions_side_owners pso
-- JOINS FOR position_side_owners
JOIN positions p ON pso.position_id = p.id -- MATCH BETWEEN positions_side_owners and positions
JOIN calibers ca ON  pso.caliber_id = ca.id  -- MATCH BETWEEN positions_side_owners and calibers (cliente)
-- JOINS FOR calibers/customer
JOIN customer_companies cc ON cc.caliber_id = ca.id -- MATCH BETWEEN customer_companies and caliber/client to get the clients fields
JOIN companies co ON cc.company_id = co.id  -- MATCH BETWEEN customer_companies and companies to get the companies fields
-- JOINS FOR positions
JOIN positions_batches pb ON pso.position_id = pb.position_id -- MATCH BETWEEN positions_side_owners and position_batches to get the batch_id for that first position created for the caliber
JOIN batch_candidates bc ON bc.batch_id = pb.batch_id -- MATCH BETWEEN batch_candidates and positions_batches to get the batch with candidates on it
JOIN batches b ON b.id = bc.batch_id -- MATCH BETWEEN batches and batch_candidates to get the date of the batch sent
JOIN candidate_events ce ON ce.position_id = pso.position_id AND ce.batch_id = b.id  -- MATCH BETWEEN candidate_events and positions_side_owners and match with batches
JOIN candidate_event_types cet ON cet.id = ce.event_id -- MATCH BETWEEN candidate_events and candidate_event_types
WHERE pso.is_owner=1  -- THE CALIBER IS THE OWNER OF THE POSITION
AND b.status = 2 -- BATCH SENT
AND cet.id = 408 -- Status: Interested. When a candidate is interested
AND ca.created >= "2019-09-01" -- Excluding calibers created before 09/01/2019
GROUP by pso.caliber_id
ORDER BY co.employees desc; -- ORDERING BY NUMBER OF EMPLOYEES (BUSINESS SIZE)
