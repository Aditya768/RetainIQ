with source as (
    select * from RETAINIQ.RAW.FIRMOGRAPHICS
),

renamed as (
    select
        customer_id,
        upper(funding_stage)                    as funding_stage,
        total_funding_usd,
        employee_count,
        founded_year,
        upper(tech_stack_size)                  as tech_stack_size,
        case when is_b2b = 1
             then true else false end           as is_b2b,
        case when has_data_team = 1
             then true else false end           as has_data_team,
        g2_rating,
        glassdoor_rating,
        current_date() - founded_year          as company_age_years,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed