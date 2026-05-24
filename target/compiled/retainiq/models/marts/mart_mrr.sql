with subscriptions as (
    select * from RETAINIQ.STAGING.stg_subscriptions
),

customers as (
    select * from RETAINIQ.STAGING.stg_customers
),

monthly_mrr as (
    select
        date_trunc('month', start_date)         as month,
        plan,
        count(*)                                as new_customers,
        sum(mrr)                                as new_mrr
    from subscriptions
    group by 1, 2
),

churned_mrr as (
    select
        date_trunc('month', end_date)           as month,
        plan,
        count(*)                                as churned_customers,
        sum(mrr)                                as churned_mrr
    from subscriptions
    where is_churned = true
    group by 1, 2
),

active_mrr as (
    select
        date_trunc('month', start_date)         as month,
        plan,
        industry,
        company_size,
        count(*)                                as active_customers,
        sum(mrr)                                as total_mrr,
        avg(mrr)                                as avg_mrr,
        min(mrr)                                as min_mrr,
        max(mrr)                                as max_mrr
    from subscriptions s
    left join customers c using (customer_id)
    where is_churned = false
    group by 1, 2, 3, 4
),

final as (
    select
        a.month,
        a.plan,
        a.industry,
        a.company_size,
        a.active_customers,
        a.total_mrr,
        a.avg_mrr,
        coalesce(m.new_customers, 0)            as new_customers,
        coalesce(m.new_mrr, 0)                  as new_mrr,
        coalesce(ch.churned_customers, 0)       as churned_customers,
        coalesce(ch.churned_mrr, 0)             as churned_mrr,
        round(coalesce(ch.churned_mrr, 0) 
            / nullif(a.total_mrr, 0) * 100, 2) as mrr_churn_rate,
        sum(a.total_mrr) over (
            partition by a.plan 
            order by a.month)                   as cumulative_mrr
    from active_mrr a
    left join monthly_mrr m 
        on a.month = m.month and a.plan = m.plan
    left join churned_mrr ch 
        on a.month = ch.month and a.plan = ch.plan
)

select * from final