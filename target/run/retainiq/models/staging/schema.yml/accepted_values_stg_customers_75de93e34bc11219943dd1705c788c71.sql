
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

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
    'Starter','Growth','Pro','Enterprise'
)



  
  
      
    ) dbt_internal_test