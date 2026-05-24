with payments as (
    select * from RETAINIQ.STAGING.stg_payments
),

customers as (
    select * from RETAINIQ.STAGING.stg_customers
),

subscriptions as (
    select * from RETAINIQ.STAGING.stg_subscriptions
),

payment_summary as (
    select
        customer_id,
        count(*)                                as total_payments,
        sum(amount)                             as total_billed,
        sum(case when is_failed 
            then amount else 0 end)             as total_failed_amount,
        sum(case when is_failed 
            then 1 else 0 end)                  as total_failed_payments,
        sum(case when not is_failed 
            then amount else 0 end)             as total_collected,
        round(sum(case when is_failed 
            then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 2)    as failure_rate_pct,
        max(payment_date)                       as last_payment_date,
        min(payment_date)                       as first_payment_date,
        count(distinct payment_month)           as paying_months
    from payments
    group by customer_id
),

monthly_trend as (
    select
        payment_month,
        count(*)                                as total_transactions,
        sum(amount)                             as total_billed,
        sum(case when is_failed 
            then 1 else 0 end)                  as failed_transactions,
        sum(case when is_failed 
            then amount else 0 end)             as failed_amount,
        round(sum(case when is_failed 
            then 1 else 0 end) 
            / nullif(count(*), 0) * 100, 2)    as monthly_failure_rate,
        upper(payment_method)                   as payment_method
    from payments
    group by 1, 7
),

final as (
    select
        ps.customer_id,
        c.company_name,
        c.plan,
        c.mrr,
        c.company_size,
        c.industry,
        s.is_churned,
        s.churn_reason,
        ps.total_payments,
        ps.total_billed,
        ps.total_collected,
        ps.total_failed_amount,
        ps.total_failed_payments,
        ps.failure_rate_pct,
        ps.last_payment_date,
        ps.first_payment_date,
        ps.paying_months,
        case
            when ps.failure_rate_pct = 0       then 'EXCELLENT'
            when ps.failure_rate_pct < 10      then 'GOOD'
            when ps.failure_rate_pct < 25      then 'AT_RISK'
            else                                    'CRITICAL'
        end                                     as payment_health_score,
        case
            when ps.failure_rate_pct > 20 
                and s.is_churned = false       then true
            else                                    false
        end                                     as involuntary_churn_risk
    from payment_summary ps
    left join customers c using (customer_id)
    left join subscriptions s using (customer_id)
)

select * from final