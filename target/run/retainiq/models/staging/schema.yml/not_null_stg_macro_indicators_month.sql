
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month
from RETAINIQ.STAGING.stg_macro_indicators
where month is null



  
  
      
    ) dbt_internal_test