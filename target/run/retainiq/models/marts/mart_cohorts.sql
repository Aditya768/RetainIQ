
  create or replace   view RETAINIQ.STAGING.mart_cohorts
  
  
  
  
  as (
    with subscriptions as (
    select * from RETAINIQ.STAGING.stg_subscriptions
),
customers as (
    select * from RETAINIQ.STAGING.stg_customers
),
cohorts as (
    select
        s.customer_id,
        date_trunc('month', s.start_date)       as cohort_month,
        s.start_date,
        s.end_date,
        s.is_churned,
        s.tenure_days,
        s.plan,
        s.mrr,
        c.industry,
        c.company_size,
        c.acquisition_channel
    from subscriptions s
    left join customers c using (customer_id)
),
retention as (
    select
        cohort_month,
        plan,
        industry,
        company_size,
        acquisition_channel,
        count(*)                                as total_customers,
        sum(case when tenure_days >= 30
            then 1 else 0 end)                  as retained_month_1,
        sum(case when tenure_days >= 90
            then 1 else 0 end)                  as retained_month_3,
        sum(case when tenure_days >= 180
            then 1 else 0 end)                  as retained_month_6,
        sum(case when tenure_days >= 365
            then 1 else 0 end)                  as retained_month_12,
        sum(case when tenure_days >= 540
            then 1 else 0 end)                  as retained_month_18,
        sum(mrr)                                as total_mrr
    from cohorts
    group by 1, 2, 3, 4, 5
),
final as (
    select
        r.cohort_month,
        r.plan,
        r.industry,
        r.company_size,
        r.acquisition_channel,
        r.total_customers,
        r.total_mrr,
        r.retained_month_1,
        r.retained_month_3,
        r.retained_month_6,
        r.retained_month_12,
        r.retained_month_18,
        round(r.retained_month_1
            / nullif(r.total_customers, 0) * 100, 1) as retention_rate_1m,
        round(r.retained_month_3
            / nullif(r.total_customers, 0) * 100, 1) as retention_rate_3m,
        round(r.retained_month_6
            / nullif(r.total_customers, 0) * 100, 1) as retention_rate_6m,
        round(r.retained_month_12
            / nullif(r.total_customers, 0) * 100, 1) as retention_rate_12m,
        round(r.retained_month_18
            / nullif(r.total_customers, 0) * 100, 1) as retention_rate_18m
    from retention r
)
select * from final
  );

