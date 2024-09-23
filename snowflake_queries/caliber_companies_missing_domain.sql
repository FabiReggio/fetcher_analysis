set candidates_threshold = 500;

select distinct
    cc.company_id
    , concat('https://admin.fetcher.ai/company/', cc.company_id) as admin_link
    , cc.name as company_name
    , cc.profile_1
    , cc.profile_2
    , cc.profile_3
    , cc.relevance
    , cc.linkedin as fetcher_linkedin
    , pdl.company_linkedin_url::string as pdl_linkedin
    , cc.domain as fetcher_domain
    , pdl.company_website::string as pdl_domain
    , cc.founded as fetcher_founded
    , pdl.company_founded::string as pdl_founded
    , cc.employees as fetcher_employees
    , pdl.company_size::string as pdl_employees
    , cc.country as fetcher_country
    , pdl.company_location_country::string as pdl_country
    , cc.region as fetcher_region
    , pdl.company_location_region::string as pdl_region
    , cc.city as fetcher_city
    , pdl.company_location_locality::string as pdl_city
from (
    select
        cc.company_id
        , c.name
        , c.linkedin
        , c.domain
        , c.founded
        , c.employees
        , c.country
        , c.region
        , c.city
        , min(case cc.candidate_order
            when 1 then cc.linkedin_profile
            else null
        end) as profile_1
        , min(case cc.candidate_order
            when 2 then cc.linkedin_profile
            else null
        end) as profile_2
        , min(case cc.candidate_order
            when 3 then cc.linkedin_profile
            else null
        end) as profile_3
        , count(cc.caliber_id) as relevance
    from (
        select
            inner_cc.*
            , dense_rank() over (
                partition by inner_cc.company_id
                order by
                    inner_cc.start_date desc
                    , inner_cc.caliber_id desc
            ) as candidate_order
            , cal.linkedin_profile
        from mysql_raw_db.aurora_caliber.caliber_companies as inner_cc
        left join base_db.aurora_caliber.calibers_vw as cal on inner_cc.caliber_id = cal.id
        where true
            and not inner_cc._fivetran_deleted
            and inner_cc.company_id not in (
                44998 -- Self-Employed
                , 2683651 -- Self-employed
                , 93 -- Self Employed
                , 438 -- Independent Consultant
                , 296 -- Independent Contractor
                , 242 -- Freelance
                , 5148 -- Sabbatical
                , 4473 -- Confidential
                , 52322 -- Autónomo
                , 44980 -- Independent
                , 932 -- Various companies
                , 2922 -- Consultant
                , 8287 -- private
                , 21028 -- Personal Projects
                , 25864 -- Contractor
            )
    ) as cc
    left join base_db.aurora_caliber.companies_vw as c on cc.company_id = c.id
    where true
        and c.domain is null
    group by
        cc.company_id
        , c.name
        , c.linkedin
        , c.domain
        , c.founded
        , c.employees
        , c.country
        , c.region
        , c.city
    having relevance >= $candidates_threshold
) as cc
left join pdl_person_raw_db.public.fetcher_experience as pdl on lower(cc.name) = lower(pdl.company_name::string)
order by
    cc.relevance desc
;