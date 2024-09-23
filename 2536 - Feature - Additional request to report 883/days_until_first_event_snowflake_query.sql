-- Days until first candidate is emailed, responded and interested --

/*
2 approaches: 
    -From first created customer
    -From first login customer 
*/

select
    temp.company_id as "Company Id"
    , temp.company_name as "Company Name"
    , temp.company_status as "Company Status"
    
    -- METRICS SINCE FIRST CREATED DATE UNTIL FIRST EVENT
    , TIMESTAMPDIFF(DAY, temp.min_created_date, temp.first_emailed_date) as "Days from first created until first emailed" 
    , TIMESTAMPDIFF(DAY, temp.min_created_date, temp.first_responded_date) as "Days from first created until first response"
    , TIMESTAMPDIFF(DAY, temp.min_created_date, temp.first_interested_date) as "Days from first created until first interested"
    
    -- METRICS SINCE FIRST LOGIN DATE UNTIL FIRST EVENT
    , TIMESTAMPDIFF(DAY, temp.min_login_date, temp.first_emailed_date) as "Days from first login until first emailed" 
    , TIMESTAMPDIFF(DAY, temp.min_login_date, temp.first_responded_date) as "Days from first login until first response"
    , TIMESTAMPDIFF(DAY, temp.min_login_date, temp.first_interested_date) as "Days from first login until first interested"
    
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
        , min(login_vw.first_login_date) as min_login_date
        , min(login_vw.created) as min_created_date
    from customer_companies cc 
    left join companies co on co.id = cc.company_id 
    left join positions_side_owners pso on pso.caliber_id = cc.caliber_id 
    left join positions_batches pb on pso.position_id = pb.position_id 
    left join batch_candidates bc on bc.batch_id = pb.batch_id       
    left join batches b on b.id = bc.batch_id
    left join positions p on p.id = pb.position_id
    left join candidate_events ce on ce.batch_id = b.id and ce.caliber_id = bc.caliber_id and ce.position_id = pso.position_id  
    -- NEW JOIN WITH CUSTOMER LOGIN VIEW
    inner join base_db.mixpanel.customer_login_event_vw as login_vw on cc.caliber_id = login_vw.user_id
    where 1=1
        and b.status = 2 -- Batch sent
        and ce.event_id in (
    			   1 -- Email Sent
    			 , 2 -- Email Sent
    			 , 14 -- Replied 
    			 , 408 -- Interested
    		)
        [[and co.id = {{company_id}}]]
        [[and co.name = {{company_name}}]]
        [[and co.status = {{company_status}}]]
    group by 
        co.id   -- GROUPED BY COMPANY ID
        , co.name
        , co.status
    ) as temp
group by temp.company_id
        , temp.company_name
        , temp.company_status
        , temp.first_emailed_date
        , temp.first_responded_date
        , temp.first_interested_date
        , temp.min_login_date 
        , temp.min_created_date  
order by temp.company_id;
    
