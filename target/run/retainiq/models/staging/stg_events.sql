
  
    

create or replace transient table RETAINIQ.STAGING.stg_events
    
    
    
    as (

with source as (
    select * from RETAINIQ.RAW.EVENTS
),

renamed as (
    select
        event_id,
        customer_id,
        upper(event_type)                       as event_type,
        event_date::date                        as event_date,
        session_duration_min,
        upper(device)                           as device,
        date_trunc('month', event_date)         as event_month,
        date_trunc('week', event_date)          as event_week,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed
    )
;


  