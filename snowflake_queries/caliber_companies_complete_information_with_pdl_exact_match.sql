select 
    company_id
    ,company_name
    , relevance
    , pdl_linkedin
    , pdl_domain
    , pdl_founded
    , pdl_employees
    , pdl_country
    , pdl_region
    , pdl_city
   , pdl_industry
from (
    select 
        distinct comp.company_id as company_id
        , comp.name as company_name
        , comp.relevance
        , pdl.company_linkedin_url::string as pdl_linkedin
        , pdl.company_website::string as pdl_domain
        , pdl.company_founded::string as pdl_founded
        , pdl.company_size::string as pdl_employees
        , pdl.company_location_country::string as pdl_country
        , pdl.company_location_region::string as pdl_region
        , pdl.company_location_locality::string as pdl_city
    , pdl.company_industry::string as pdl_industry
    , case
            when pdl.company_size = '1-10' then 1
            when pdl.company_size = '11-50' then 2
            when pdl.company_size = '51-200' then 3
            when pdl.company_size = '201-500' then 4
            when pdl.company_size = '501-1000' then 5
            when pdl.company_size = '1001-5000' then 6
            when pdl.company_size = '5001-10000' then 7
            when pdl.company_size = '10001+' then 8
            else 0 -- null or empty
        end as size_order
    , row_number() over (partition by comp.company_id order by size_order desc) as row_number
    from (
            select
                cc.company_id
                , c.name
                , count(cc.caliber_id) as relevance
            from mysql_raw_db.aurora_caliber.caliber_companies as cc
            left join base_db.aurora_caliber.companies_vw as c on cc.company_id = c.id
            where true
                and (c.domain is null or c.domain = '') 
                and not cc._fivetran_deleted
                and c.id not in (
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
            group by
                cc.company_id
                , c.name
            having relevance between 100 and 499
        ) as comp 
    join pdl_person_raw_db.public.fetcher_experience as pdl on lower(comp.name) = lower(pdl.company_name::string)
    where true
        and pdl.company_website is not null and pdl.company_website != '' 
    order by
        comp.relevance desc
        , comp.company_id
) as main
where main.row_number = 1