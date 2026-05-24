
  create or replace   view RETAINIQ.STAGING.stg_subscriptions
  
  
  
  
  as (
    with source as (
    select * from RETAINIQ.RAW.SUBSCRIPTIONS
),

renamed as (
    select
        subscription_id,
        customer_id,
        upper(plan)                             as plan,
        mrr,
        upper(status)                           as status,
        start_date::date                        as start_date,
        end_date::date                          as end_date,
        case when churned = 1 
             then true else false end           as is_churned,
        upper(churn_reason)                     as churn_reason,
        datediff('day', start_date, 
            coalesce(end_date, current_date())) as tenure_days,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed
  );

