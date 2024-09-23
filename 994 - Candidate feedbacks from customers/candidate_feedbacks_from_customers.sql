select
    positions_batches.position_id as 'Position ID'
    , positions.name as 'Position name'
    , bc.batch_id as 'Batch ID'
    , concat(candidate.first_name, ' ', candidate.last_name) as 'Candidate'
    , case
        when bc.contact_status > 0 then 'Yes'
        else 'No'
    end as 'Contacted'
    , case bc.liked
        when 1 then 'Liked'
        when 2 then 'Disliked'
        else 'None'
    end as 'Feedback'
    , coalesce(comments.comment, 'No comment') as 'Comment'
    , case
        when bc.liked != 0 then concat(customer_likes.first_name, ' ', customer_likes.last_name)
        else concat(customer.first_name, ' ', customer.last_name)
    end as 'Customer'
    , case
        when comments.created is not null then comments.created
        else events.created
    end  as 'Event date'
from positions_batches
inner join batch_candidates as bc on bc.batch_id = positions_batches.batch_id
left join comments on
    comments.batch_id = bc.batch_id
    and comments.candidate_id = bc.caliber_id
left join positions on positions.id = positions_batches.position_id
left join calibers as candidate on candidate.id = bc.caliber_id
left join calibers as customer on customer.id=comments.member_id
left join candidate_events as events on events.position_id = positions.id and events.caliber_id = bc.caliber_id and events.event_id in (201, 202)
left join calibers as customer_likes on customer_likes.id = events.custom_description
where true
    [[and {{company_id}}]]
    [[and {{position_id}}]]
    [[and {{batch_id}}]]
    [[and if(comments.id is null, 'no', 'yes') = lower({{has_comment}})]]
