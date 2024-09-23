-- Candidate's Comments - Metabase Query 

select 
    c.position_id 
    , c.batch_id 
    , c.member_id as customer_id 
    , concat(customer.first_name,' ',customer.last_name) as customer_name
    , c.candidate_id
    , concat(candidate.first_name,' ',candidate.last_name) as candidate_name
    , c.comment as candidate_comment
    , c.created as created
from comments as c
left join calibers as candidate 
    on candidate.id = c.candidate_id
left join calibers as customer 
    on customer.id = c.member_id
where true
[[and c.position_id={{position_id}}]]
[[and c.batch_id={{batch_id}}]]
[[and c.member_id={{customer_id}}]]
[[and c.candidate_id={{candidate_id}}]]
order by 
    c.position_id asc
    , c.batch_id asc
    , c.created asc