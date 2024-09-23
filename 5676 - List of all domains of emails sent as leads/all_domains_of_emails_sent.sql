select 
    domain
    , count(*) as number_of_candidates
from (
    select
        ce.to_id as candidate_id
        , ce.to_email as candidate_email
        , (SUBSTRING_INDEX(SUBSTR(ce.to_email, INSTR(ce.to_email, '@') + 1),'.',2)) as domain 
    from candidate_message ce
    group by ce.to_id
    ) as temp
group by temp.domain
order by count(*) desc; 
