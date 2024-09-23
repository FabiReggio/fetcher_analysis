select
	temp.company_id
	, count(distinct temp.caliber_id) as memebers_count
	, sum(temp.greenhouse_sync_flag) as memebers_using_gh
	, sum(temp.greenhouse_sync_flag) / count(distinct temp.caliber_id) as greenhouse_sync_rate
	, sum(temp.smart_recruiters_sync_flag) as memebers_using_sr
	, sum(temp.smart_recruiters_sync_flag) / count(distinct temp.caliber_id) as smart_recruiters_sync_rate
	, sum(temp.smashfly_users_sync_flag) as memebers_using_su
	, sum(temp.smashfly_users_sync_flag) / count(distinct temp.caliber_id) as smashfly_sync_rate
	, sum(temp.compas_users_sync_flag) as memebers_using_cu
	, sum(temp.compas_users_sync_flag) / count(distinct temp.caliber_id) as compas_sync_rate
from (
	select
		cc.*
		, if(gh.customer_id is null, FALSE, TRUE) as greenhouse_sync_flag
		, if(sr.customer_id is null, FALSE, TRUE) as smart_recruiters_sync_flag
		, if(su.customer_id is null, FALSE, TRUE) as smashfly_users_sync_flag
		, if(cu.customer_id is null, FALSE, TRUE) as compas_users_sync_flag
	from customer_companies as cc
	left join greenhouse_access_tokens as gh on gh.customer_id = cc.caliber_id
	left join smart_recruiters_tokens as sr on sr.customer_id = cc.caliber_id
	left join smashfly_users as su on su.customer_id = cc.caliber_id
	left join compas_users as cu on cu.customer_id = cc.caliber_id
	where 1=1
		{filter_flag} and cc.company_id in {filter_values}
) as temp
group by
	temp.company_id