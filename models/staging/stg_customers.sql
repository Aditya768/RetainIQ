with source as (
    select * from RETAINIQ.RAW.CUSTOMERS
),

renamed as (
    select
        customer_id,
        company_name,
        upper(industry)                          as industry,
        upper(company_size)                      as company_size,
        upper(acquisition_channel)               as acquisition_channel,
        upper(plan)                              as plan,
        mrr,
        signup_date::date                        as signup_date,
        upper(country)                           as country,
        case when has_upgraded = 1 
             then true else false end            as has_upgraded,
        support_tickets_total,
        case when onboarding_completed = 1 
             then true else false end            as onboarding_completed,
        nps_score,
        current_timestamp()                      as loaded_at
    from source
)

select * from renamed