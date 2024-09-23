select
	temp.company_id
	, temp.company_name
	, count(distinct temp.position_id) as positions_count
	, sum(temp.batches_sent) as batches_sent
	, sum(temp.total_leads) as total_leads
	, sum(temp.fetcher_leads) as fetcher_leads
	, sum(temp.fetcher_leads) / sum(temp.total_leads) as fetcher_leads_rate
	, sum(temp.copied_leads) as copied_leads
	, sum(temp.copied_leads) / sum(temp.total_leads) as copied_leads_rate
	, sum(temp.extension_leads) as extension_leads
	, sum(temp.extension_leads) / sum(temp.total_leads) as extension_leads_rate
	, sum(temp.likes) as likes
	, sum(temp.likes) / sum(temp.total_leads) as likes_rate
	, sum(temp.dislikes) as dislikes
	, sum(temp.dislikes) / sum(temp.total_leads) as dislikes_rate
	, sum(temp.unvetted) as unvetted
	, sum(temp.unvetted) / sum(temp.total_leads) as unvetted_rate
	, sum(temp.emailed) as emailed
	, sum(temp.emailed) / sum(temp.total_leads) as emailed_rate
	, sum(temp.responded) as responded
	, sum(temp.responded) / sum(temp.emailed) as responded_rate
	, sum(temp.interested) as interested
	, sum(temp.interested) / sum(temp.total_leads) as interested_rate
	, sum(temp.interested) / sum(temp.responded) as interested_rate_over_responded
	, sum(temp.not_interested) as not_interested
	, sum(temp.not_interested) / sum(temp.total_leads) as not_interested_rate
	, sum(temp.females) / sum(temp.total_leads) as female_rate
	, sum(temp.males) / sum(temp.total_leads) as male_rate
	, (sum(temp.total_leads) - sum(temp.females) - sum(temp.males)) / sum(temp.total_leads) as unknown_gender
	, sum(temp.blacks) / sum(temp.total_leads) as blacks_rate
	, sum(temp.hispanics) / sum(temp.total_leads) as hispanics_rate
	, sum(temp.whites) / sum(temp.total_leads) as whites_rate
	, sum(temp.asians) / sum(temp.total_leads) as asians_rate
	, (sum(temp.total_leads) - (
			sum(temp.blacks)
			+sum(temp.hispanics)
			+sum(temp.whites)
			+sum(temp.asians)
			)
		) / sum(temp.total_leads) as other_ethnicity
from (
	select
		cc.company_id
		, companies.name as company_name
		, pso.position_id as position_id
		, count(distinct batches.id) as batches_sent
		, case
			when batches.type = 1 then count(distinct bc.caliber_id)
			else 0
		end as fetcher_leads
		, case
			when batches.type = 2 then count(distinct bc.caliber_id)
			else 0
		end as copied_leads
		, case
			when batches.type = 3 then count(distinct bc.caliber_id)
			else 0
		end as extension_leads
		, count(distinct bc.caliber_id) as total_leads
		, sum(
			case
				when (
					bc.contact_status = 0 -- NON-CONTACTED
					and bc.status <= 2 -- NEW or VIEWED candidate
					and bc.liked = 0 -- NEUTRAL STATUS (nor like neither dislike)
				) then 1
				else 0
			end
		) as unvetted
		, sum(
			case
				when bc.liked = 1 then 1
				else 0
			end
		) as likes
		, sum(
			case
				when bc.liked = 2 then 1
				else 0
			end
		) as dislikes
		, sum(
			case
				when bc.contact_status >= 1 then 1
				else 0
			end
		) as emailed
		, sum(bc.responded) as responded
		, sum(coalesce(cis.status, 0)) as interested
		, sum(
			case
				when cis.status = 0 then 1
				else 0
			end
		) as not_interested
		, sum(
			case
				when lower(cg.gender_label) = 'female' then 1
				else 0
			end
		) as females
		, sum(
			case
				when lower(cg.gender_label) = 'male' then 1
				else 0
			end
		) as males
		, sum(
			case
				when lower(ce.ethnicity_label) like '%black%' then 1
				else 0
			end
		) as blacks
		, sum(
			case
				when lower(ce.ethnicity_label) like '%hispanic%' then 1
				else 0
			end
		) as hispanics
		, sum(
			case
				when lower(ce.ethnicity_label) like '%white%' then 1
				else 0
			end
		) as whites
		, sum(
			case
				when lower(ce.ethnicity_label) like '%asian%' then 1
				else 0
			end
		) as asians
	from customer_companies as cc
	left join positions_side_owners as pso on
		pso.caliber_id = cc.caliber_id
		and pso.is_owner = 1
	left join positions_batches as pb on pb.position_id = pso.position_id
	left join batch_candidates as bc on bc.batch_id = pb.batch_id
	left join candidate_interested_status as cis on
		cis.candidate_id = bc.caliber_id
		and cis.position_id = pb.position_id
	left join batches on batches.id = pb.batch_id
	left join companies on companies.id = cc.company_id
	left join candidate_gender as cg on cg.candidate_id = bc.caliber_id
	left join candidate_ethnicity as ce on ce.candidate_id = bc.caliber_id
	where 1=1
		and pso.position_id is not null
		and batches.status = 2
		{filter_flag} and companies.id in {filter_values}
	group by
		cc.company_id
		, pso.position_id
		, batches.id
) as temp
group by
	temp.company_id
order by
    sum(temp.total_leads) desc