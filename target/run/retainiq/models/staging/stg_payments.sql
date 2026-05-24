
  create or replace   view RETAINIQ.STAGING.stg_payments
  
  
  
  
  as (
    with source as (
    select * from RETAINIQ.RAW.PAYMENTS
),

renamed as (
    select
        payment_id,
        customer_id,
        payment_date::date                      as payment_date,
        amount,
        upper(status)                           as status,
        upper(payment_method)                   as payment_method,
        case when upper(status) = 'FAILED' 
             then true else false end           as is_failed,
        date_trunc('month', payment_date)       as payment_month,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed
  );

