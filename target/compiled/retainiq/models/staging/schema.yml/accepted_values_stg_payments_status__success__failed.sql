
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from RETAINIQ.STAGING.stg_payments
    group by status

)

select *
from all_values
where value_field not in (
    'SUCCESS','FAILED'
)


