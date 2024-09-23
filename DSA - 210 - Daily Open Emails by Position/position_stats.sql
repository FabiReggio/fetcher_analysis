-- Position Stats

select
    company_id
    , company_name
    , position_id 
    , position_name 
    , position_owner_id 
    , position_owner_name
    , sum(added_to_search) as added_to_search
    , sum(scheduled) as scheduled
    , sum(emailed) as emailed
    , sum(first_follow_up) as first_follow_up
    , sum(second_follow_up) as second_follow_up
    , sum(replies) as replies
    -- Interest
    , sum(interested) as interested
    , sum(undo_interested) as undo_interested
    , sum(interest_minus_undo_interest) as interest_minus_undo_interest
    -- Hired
    , sum(hired) as hired
    , sum(undo_hired) as undo_hired
    , sum(hired_minus_undo_hired) as hired_minus_undo_hired
    -- Liked
    , sum(liked) as liked
    , sum(undo_like) as undo_like 
    , sum(liked_minus_undo_like) as liked_minus_undo_like
    -- Disliked
    , sum(disliked) as disliked
    , sum(undo_dislike) as undo_dislike
    , sum(disliked_minus_undo_dislike) as disliked_minus_undo_dislike
    -- Open Emails
    , sum(open_emails) as open_emails
from report_db.metabase.daily_company_position_full_stats_vw 
where 1=1
    [[and company_id = {{company_id}}]]
    [[and {{position_id}}]]
    [[and event_date between {{start_date}} and {{end_date}}]]
group by
    company_id
    , company_name
    , position_id
    , position_name
    , position_owner_id 
    , position_owner_name
order by 
    company_id
    , position_id