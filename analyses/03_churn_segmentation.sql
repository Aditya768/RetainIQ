-- ============================================================
-- RetainIQ: Churn Segmentation Analysis
-- Purpose: Break down churn by multiple dimensions to identify
--          which customer segments have highest churn risk
-- Technique: Multi-dimensional grouping + ratio calculations
-- ============================================================

with base as (
    select
        c.customer_id,
        c.plan,
        c.industry,
        c.company_size,
        c.acquisition_channel,
        c.country,
        c.nps_score,
        c.mrr,
        s.is_churned,
        s.churn_reason,
        s.tenure_days,
        f.funding_stage,
        f.has_data_team,

        -- Engagement bucket
        case
            when e.days_since_last_active <= 7   then 'Highly Engaged'
            when e.days_since_last_active <= 30  then 'Active'
            when e.days_since_last_active <= 90  then 'At Risk'
            else                                      'Disengaged'
        end                                          as engagement_bucket,

        -- Tenure bucket
        case
            when s.tenure_days < 90              then '0-3 Months'
            when s.tenure_days < 180             then '3-6 Months'
            when s.tenure_days < 365             then '6-12 Months'
            else                                      '12+ Months'
        end                                          as tenure_bucket

    from {{ ref('stg_customers') }} c
    left join {{ ref('stg_subscriptions') }} s      using (customer_id)
    left join {{ ref('stg_firmographics') }} f       using (customer_id)
    left join {{ ref('mart_customer_churn') }} e     using (customer_id)
),

-- Churn by plan
by_plan as (
    select
        'Plan'                                       as dimension,
        plan                                         as segment,
        count(*)                                     as total_customers,
        sum(case when is_churned then 1 else 0 end)  as churned,
        sum(case when is_churned then mrr else 0 end) as churned_mrr,
        round(avg(case when is_churned then 1.0 else 0 end) * 100, 1) as churn_rate
    from base
    group by plan
),

-- Churn by industry
by_industry as (
    select
        'Industry'                                   as dimension,
        industry                                     as segment,
        count(*)                                     as total_customers,
        sum(case when is_churned then 1 else 0 end)  as churned,
        sum(case when is_churned then mrr else 0 end) as churned_mrr,
        round(avg(case when is_churned then 1.0 else 0 end) * 100, 1) as churn_rate
    from base
    group by industry
),

-- Churn by acquisition channel
by_channel as (
    select
        'Acquisition Channel'                        as dimension,
        acquisition_channel                          as segment,
        count(*)                                     as total_customers,
        sum(case when is_churned then 1 else 0 end)  as churned,
        sum(case when is_churned then mrr else 0 end) as churned_mrr,
        round(avg(case when is_churned then 1.0 else 0 end) * 100, 1) as churn_rate
    from base
    group by acquisition_channel
),

-- Churn by tenure bucket
by_tenure as (
    select
        'Tenure'                                     as dimension,
        tenure_bucket                                as segment,
        count(*)                                     as total_customers,
        sum(case when is_churned then 1 else 0 end)  as churned,
        sum(case when is_churned then mrr else 0 end) as churned_mrr,
        round(avg(case when is_churned then 1.0 else 0 end) * 100, 1) as churn_rate
    from base
    group by tenure_bucket
)

select * from by_plan
union all
select * from by_industry
union all
select * from by_channel
union all
select * from by_tenure
order by dimension, churn_rate desc