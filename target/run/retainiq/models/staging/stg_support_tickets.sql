
  create or replace   view RETAINIQ.STAGING.stg_support_tickets
  
  
  
  
  as (
    with source as (
    select * from RETAINIQ.RAW.SUPPORT_TICKETS
),

renamed as (
    select
        ticket_id,
        customer_id,
        upper(category)                         as category,
        upper(priority)                         as priority,
        created_date::date                      as created_date,
        resolution_hours,
        case when resolved = 1
             then true else false end           as is_resolved,
        satisfaction_score,
        case
            when resolution_hours < 4  then 'fast'
            when resolution_hours < 24 then 'normal'
            else 'slow'
        end                                     as resolution_speed,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed
  );

