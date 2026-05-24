
    
    

select
    subscription_id as unique_field,
    count(*) as n_records

from RETAINIQ.STAGING.stg_subscriptions
where subscription_id is not null
group by subscription_id
having count(*) > 1


