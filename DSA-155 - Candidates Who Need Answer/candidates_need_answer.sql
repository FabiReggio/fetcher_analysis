select 
    companies.id as company_id
    , companies.name as company_name
    , case 
        when companies.status = 1 then 'Active' 
        when companies.status = 2 then 'Canceled' 
        else null
      end as company_status
    , pso.position_id as position_id
    , positions.name as position_name
    , case 
		when positions.status = 1 then 'New'
		when positions.status = 2 then 'Open'
		when positions.status = 3 then 'Closed'
		when positions.status = 4 then 'Hold'
	end as position_status
	, candidate_message.from_id as candidate_id /* sender_id */
	, concat(sender.first_name, ' ', sender.last_name) as candidate_name /* sender_name */
	, candidate_message.from_email as candidate_email /* from_email */
	, case 
        when ct.status = 0 then 'Resolved'
		when ct.status = 1 then 'Needs Answer'
	end as email_status /* candidate_thread_status */
	, candidate_message.to_id  as responder_id /* receiver_id */
	, concat(receiver.first_name, ' ', receiver.last_name) as responder_name /* receiver_name */
	, candidate_message.to_email as responder_email /* to_email */
	, candidate_message.created as response_date
from customer_companies as cc 
left join companies 
    on companies.id = cc.company_id 
left join positions_side_owners as pso 
    on pso.caliber_id = cc.caliber_id 
left join calibers as customer 
    on pso.caliber_id = customer.id 
left join positions 
    on positions.id = pso.position_id
-- Candidate Message 
left join candidate_thread ct 
    on ct.position_id = positions.id 
left join candidate_thread_messages ctm 
    on ctm.thread_id = ct.id
left join candidate_message 
    on candidate_message.id = ctm.message_id 
    and candidate_message.from_id = ct.candidate_id
-- Message Sender Information
left join calibers as sender 
    on candidate_message.from_id = sender.id
-- Message Receiver Information
left join calibers as receiver 
    on candidate_message.to_id = receiver.id
where 1=1
    and pso.position_id is not null
    and ct.status = 1 -- Needs Answer
    and candidate_message.email_type = 9 -- EMAIL_QUEUE_RESPONSE_TYPE
    [[and {{company_id}}]]
    [[and {{company_name}}]]
    [[and {{company_status}}]]
    [[and {{position_status}}]]
    [[and {{response_date}}]]
    [[and {{candidate_id}}]]
    [[and {{responder_id}}]]
group by
    companies.id
    , pso.position_id
    , ct.batch_id 
    , ct.candidate_id
order by 
    companies.id
    , pso.position_id
    , ct.batch_id
    , ct.candidate_id;
