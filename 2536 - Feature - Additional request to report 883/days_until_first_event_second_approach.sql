-- Days until first candidate is emailed, responded and interested --

select
    temp.company_id as "Company Id"
    , temp.company_name as "Company Name"
    , temp.company_status as "Company Status"
    , TIMESTAMPDIFF(DAY, temp.first_added_to_search_date, temp.first_emailed_date) as "Days until first candidate is emailed"
    , TIMESTAMPDIFF(DAY, temp.first_added_to_search_date, temp.first_responded_date) as "Days until first candidate responded"
    , TIMESTAMPDIFF(DAY, temp.first_added_to_search_date, temp.first_interested_date) as "Days until first candidate is interested" 
from (
    select 
        co.id as company_id
        , co.name as company_name
        , case 
            when co.status = 1 then 'Active' 
            when co.status = 2 then 'Canceled'
            else null
        end as company_status
        , min(
    		case
    			when ce.event_id=101 then ce.created
    			else null
    		end
    	) as first_added_to_search_date
        , min(
    		case
    			when ce.event_id in (1,2) then ce.created
    			else null
    		end
    	) as first_emailed_date
         , min(
			case
				when ce.event_id = 14 then ce.created
				else null
			end
    	) as first_responded_date
        , min(
			case
				when ce.event_id = 408 then ce.created
				else null
			end
    	) as first_interested_date
    		
    from customer_companies cc 
    left join companies co on co.id = cc.company_id 
    left join positions_side_owners pso on pso.caliber_id = cc.caliber_id 
    left join positions_batches pb on pso.position_id = pb.position_id 
    left join batch_candidates bc on bc.batch_id = pb.batch_id       
    left join batches b on b.id = bc.batch_id
    left join positions p on p.id = pb.position_id
    left join candidate_events ce on ce.batch_id = b.id and ce.caliber_id = bc.caliber_id and ce.position_id = pso.position_id  
    where 1=1
        and b.status = 2 -- Batch sent
        and pso.is_owner = 1
        and ce.event_id in (
    			   1 -- Email Sent
    			 , 2 -- Email Sent
    			 , 14 -- Replied 
    			 , 408 -- Interested
    			 , 101 -- Added to Search
    		)
    	
        [[and co.id = {{company_id}}]]
        [[and co.name = {{company_name}}]]
        [[and co.status = {{company_status}}]]
    group by 
        co.id -- GROUPED BY COMPANY ID
    ) as temp
group by temp.company_id;