set @awl = 9; -- Average Word Length parameter. Here we use a bigger value to include the HTML tags
select
	case
		when char_length(cm.email_body) <  (100 * @awl) then 'Less than 100 words'
		when char_length(cm.email_body) >= (100 * @awl) and char_length(cm.email_body) < (200 * @awl) then '[100 - 200) words'
		when char_length(cm.email_body) >= (200 * @awl) and char_length(cm.email_body) < (300 * @awl) then '[200 - 300) words'
		when char_length(cm.email_body) >= (300 * @awl) and char_length(cm.email_body) < (400 * @awl) then '[300 - 400) words'
		when char_length(cm.email_body) >= (400 * @awl) and char_length(cm.email_body) < (500 * @awl) then '[400 - 500) words'
		when char_length(cm.email_body) >= (500 * @awl) and char_length(cm.email_body) < (600 * @awl) then '[500 - 600) words'
		when char_length(cm.email_body) >= (600 * @awl) and char_length(cm.email_body) < (700 * @awl) then '[600 - 700) words'
		when char_length(cm.email_body) >= (700 * @awl) then '700+ words'
		else null
	end as 'Words'
	, count(distinct cm.id) as 'Total messages'
	, sum(tp.status) / count(distinct cm.id) as 'Open'
	, sum(bc.responded) / count(distinct cm.id) as 'Response'
	, count(cis.status) as 'With interest info'
	, count(distinct cm.id) - count(cis.status) as 'Unknown interest status'
	, sum(cis.status) / count(cis.status) as 'Interested'
-- select *
from batch_candidates as bc
left join candidate_thread as ct on
	ct.batch_id = bc.batch_id
	and ct.candidate_id = bc.caliber_id
left join candidate_thread_messages as ctm on ctm.thread_id = ct.id
left join candidate_message as cm on cm.id = ctm.message_id
left join tracking_pixels as tp on tp.id = cm.pixel_id
left join candidate_interested_status as cis on
	cis.position_id = ct.position_id
	and cis.candidate_id = bc.caliber_id
where 1=1
	-- and cm.to_email not like '%@fetcher%'
	and cm.email_type = 0
	and date(bc.contact_date) >= date_sub(curdate(), interval 90 day)
group by
	Words
order by
	count(distinct cm.id) desc
;