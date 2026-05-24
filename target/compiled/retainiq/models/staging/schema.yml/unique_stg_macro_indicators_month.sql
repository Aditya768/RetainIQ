
    
    

select
    month as unique_field,
    count(*) as n_records

from RETAINIQ.STAGING.stg_macro_indicators
where month is not null
group by month
having count(*) > 1


