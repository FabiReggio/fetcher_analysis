select
	cont.company_id
	, sum(ct.seats_paid) as seats_paid
	, sum(ct.seats_used) as seats_used
	, (sum(ct.seats_used) / sum(ct.seats_paid)) as seats_used_rate
from contracts as cont
left join contract_trackings as ct on ct.contract_id = cont.id
group by
	cont.company_id