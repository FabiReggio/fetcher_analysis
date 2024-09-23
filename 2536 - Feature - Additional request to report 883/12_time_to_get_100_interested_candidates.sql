-- Time to get 100 interested candidates -- 

select
	rank_table.company_id,
    rank_table.company_name,
    -- rank_table.contract_id,
    -- rank_table.contract_start_date,
    -- rank_table.contract_end_date,
    -- rank_table.position_id,
    -- rank_table.batch_id,
    -- rank_table.event_id,
    -- rank_table.event_date,
    -- rank_table.email_order,
	datediff(rank_table.event_date, rank_table.contract_start_date) as "Time to get 100 interested candidates"
from (
	select
		data_table.*
		, @order_rank := IF(
	        @current_company = data_table.company_id
	        , @order_rank + 1
	        , 1
	    ) AS email_order
	    , @current_company := data_table.company_id as current_company
	from (
		select
		    cc.company_id,
		    co.name as company_name,
		    -- cont.id as contract_id,
		    cont.start_date as contract_start_date,
		    -- cont.end_date as contract_end_date,
		    -- ce.position_id,
		    -- ce.batch_id,
		    -- ce.event_id,
		    ce.created as event_date
		from contracts as cont
	    left join companies as co on co.id = cont.company_id
		left join customer_companies as cc on cc.company_id = co.id
		left join positions_side_owners as pso on
			pso.caliber_id = cc.caliber_id
			and pso.is_owner = 1
			and pso.created between cont.start_date and cont.end_date
		left join positions_batches as pb on pb.position_id = pso.position_id
		left join candidate_events as ce on
			ce.batch_id = pb.batch_id
			and ce.position_id = pb.position_id
			-- Considering event creation date in the range of start date and end date of each contract
			and ce.created between cont.start_date and cont.end_date 
		where 1=1 
		and ce.event_id = 408 -- Interested
		[[and cc.company_id = {{company_id}} ]]
		[[and co.name = {{company_name}}]]
		order by
			cc.company_id, ce.created
	) as data_table
) as rank_table
where 1=1
   and rank_table.email_order = 100
order by rank_table.company_name;