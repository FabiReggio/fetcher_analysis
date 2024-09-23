select distinct
    cc.company_id
    , concat('https://admin.fetcher.ai/company/', cc.company_id) as admin_link
    , c.name as company_name
    , c.linkedin as fetcher_linkedin
    , pdl.company_linkedin_url::string as pdl_linkedin
    , c.domain as fetcher_domain
    , pdl.company_website::string as pdl_domain
    , s.website as salesforce_domain
    , c.founded as fetcher_founded
    , pdl.company_founded::string as pdl_founded
    , c.employees as fetcher_employees
    , pdl.company_size::string as pdl_employees
    , s.number_of_employees as salesforce_employees
    , c.country as fetcher_country
    , pdl.company_location_country::string as pdl_country
    , s.billing_country as salesforce_country
    , c.region as fetcher_region
    , pdl.company_location_region::string as pdl_region
    , s.billing_state as salesforce_region
    , c.city as fetcher_city
    , pdl.company_location_locality::string as pdl_city
    , s.billing_city as salesforce_city
from base_db.aurora_caliber.customer_companies_vw as cc
left join base_db.aurora_caliber.companies_vw as c on cc.company_id = c.id
left join salesforce_raw_db.salesforce_live.account as s on
    (
        cc.company_id = s.admin_id_c
        or c.name = s.name
    )
    and not s.is_deleted
left join pdl_person_raw_db.public.fetcher_experience as pdl on lower(c.name) = lower(pdl.company_name::string)
where true
    and c.domain is null
;