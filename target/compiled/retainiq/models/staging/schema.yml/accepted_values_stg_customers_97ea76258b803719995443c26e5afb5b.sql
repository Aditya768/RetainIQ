
    
    

with all_values as (

    select
        plan as value_field,
        count(*) as n_records

    from RETAINIQ.STAGING.stg_customers
    group by plan

)

select *
from all_values
where value_field not in (
    'STARTER','GROWTH','PRO','ENTERPRISE'
)


