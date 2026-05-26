-- ============================================================
-- RetainIQ: MRR Movement Analysis
-- Purpose: Track New MRR, Churned MRR, and Net MRR change
--          month over month — the core SaaS revenue metric
-- Technique: CTEs + window functions + lag()
-- ============================================================

with monthly_cohorts as (
    select
        date_trunc('month', start_date)             as month,
        plan,
        company_size,
        sum(mrr)                                     as new_mrr,
        count(*)                                     as new_customers
    from {{ ref('stg_subscriptions') }}
    group by 1, 2, 3
),

monthly_churn as (
    select
        date_trunc('month', end_date)               as month,
        plan,
        company_size,
        sum(mrr)                                     as churned_mrr,
        count(*)                                     as churned_customers
    from {{ ref('stg_subscriptions') }}
    where is_churned = true
      and end_date is not null
    group by 1, 2, 3
),

active_mrr as (
    select
        date_trunc('month', start_date)             as month,
        plan,
        company_size,
        sum(mrr)                                     as active_mrr,
        count(*)                                     as active_customers
    from {{ ref('stg_subscriptions') }}
    where is_churned = false
    group by 1, 2, 3
),

combined as (
    select
        a.month,
        a.plan,
        a.company_size,
        a.active_mrr,
        a.active_customers,
        coalesce(n.new_mrr, 0)                      as new_mrr,
        coalesce(n.new_customers, 0)                as new_customers,
        coalesce(ch.churned_mrr, 0)                 as churned_mrr,
        coalesce(ch.churned_customers, 0)           as churned_customers
    from active_mrr a
    left join monthly_cohorts n
        on a.month = n.month 
        and a.plan = n.plan 
        and a.company_size = n.company_size
    left join monthly_churn ch
        on a.month = ch.month 
        and a.plan = ch.plan 
        and a.company_size = ch.company_size
),

final as (
    select
        *,
        -- Net MRR change
        new_mrr - churned_mrr                       as net_mrr_change,

        -- MRR churn rate
        round(churned_mrr 
            / nullif(active_mrr, 0) * 100, 2)       as mrr_churn_rate_pct,

        -- Running total MRR
        sum(new_mrr - churned_mrr) over (
            partition by plan
            order by month
            rows unbounded preceding)               as cumulative_net_mrr,

        -- Month over month growth
        round((active_mrr - lag(active_mrr) over (
            partition by plan 
            order by month))
            / nullif(lag(active_mrr) over (
            partition by plan 
            order by month), 0) * 100, 2)           as mom_growth_pct
    from combined
)

select * from final
order by month desc, plan