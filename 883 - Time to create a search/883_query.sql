SELECT
    ca.first_name as "First Name",
    ca.last_name as "Last Name",
    co.name as "Company Name",
    TIMESTAMPDIFF(DAY,ca.created, pso.created) AS "Time for the first user at our customer to create their first position", -- Time position was created by their owner - Caliber created Time  
    co.employees as "Business Size"
FROM positions_side_owners pso
-- JOINS FOR position_side_owners
JOIN positions p ON pso.position_id = p.id -- MATCH BETWEEN positions_side_owners and positions
JOIN calibers ca ON  pso.caliber_id = ca.id  -- MATCH BETWEEN positions_side_owners and calibers (cliente)
-- JOINS FOR calibers/customer
JOIN customer_companies cc ON cc.caliber_id = ca.id -- MATCH BETWEEN customer_companies and caliber/client to get the clients fields
JOIN companies co ON cc.company_id = co.id  -- MATCH BETWEEN customer_companies and companies to get the companies fields
WHERE pso.is_owner=1  -- THE CALIBER IS THE OWNER OF THE POSITION
GROUP BY pso.caliber_id
ORDER BY co.employees desc; -- ORDERING BY NUMBER OF EMPLOYEES (BUSINESS SIZE)