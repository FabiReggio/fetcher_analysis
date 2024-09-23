	-- Response, Contact rate based on time of day that email is sent - without local timezone

	select 
	    hour(bc.contact_date) as hour_contact_date
	    , sum(case when bc.contact_status >= 1 then 1 else 0 end) as contacted
	    , sum(case when bc.responded = 1 then 1 else 0 end) as responses
	    , sum(case when bc.contact_status >= 1 then 1 else 0 end)/count(bc.caliber_id) as contact_rate
	    , sum(case when bc.responded = 1 then 1 else 0 end) / sum(case when bc.contact_status >= 1 then 1 else 0 end) as response_rate
	from batch_candidates bc
	where 1=1 
	    and bc.contact_date!='0000-00-00 00:00:00'
	    and year(bc.created) >= [[{{year}}]]
	group by hour(bc.contact_date)
	order by hour(bc.contact_date);
