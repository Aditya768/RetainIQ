-- ============================================================
-- RetainIQ: Cohort Retention Analysis
-- Purpose: Calculate what % of customers from each signup 
--          month are still active at 1, 3, 6, 12 months
-- Technique: Window functions + date_trunc + conditional agg
-- ============================================================

with cohorts as (
    select
        c.customer_id,
        date_trunc('month', s.start_date)           as cohort_month,
        s.tenure_days,
        s.is_churned,
        s.mrr,
        c.plan,
        c.acquisition_channel
    from {{ ref('stg_subscriptions') }} s
    left join {{ ref('stg_customers') }} c using (customer_id)
),

retention_calc as (
    select
        cohort_month,
        plan,
        acquisition_channel,
        count(*)                                     as cohort_size,
        sum(mrr)                                     as cohort_mrr,

        -- Retention at each milestone
        sum(case when tenure_days >= 30  then 1 else 0 end)  as retained_1m,
        sum(case when tenure_days >= 90  then 1 else 0 end)  as retained_3m,
        sum(case when tenure_days >= 180 then 1 else 0 end)  as retained_6m,
        sum(case when tenure_days >= 365 then 1 else 0 end)  as retained_12m,

        -- Retention rates
        round(sum(case when tenure_days >= 30  then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 1)          as retention_rate_1m,
        round(sum(case when tenure_days >= 90  then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 1)          as retention_rate_3m,
        round(sum(case when tenure_days >= 180 then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 1)          as retention_rate_6m,
        round(sum(case when tenure_days >= 365 then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 1)          as retention_rate_12m
    from cohorts
    group by 1, 2, 3
),

-- Add month-over-month retention change
with_trend as (
    select
        *,
        retention_rate_1m - lag(retention_rate_1m) over (
            partition by plan 
            order by cohort_month)                   as mom_retention_change
    from retention_calc
)

select * from with_trend
order by cohort_month desc, plan