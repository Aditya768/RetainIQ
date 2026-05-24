
  create or replace   view RETAINIQ.STAGING.mart_customer_churn
  
  
  
  
  as (
    with customers as (
    select * from RETAINIQ.STAGING.stg_customers
),
subscriptions as (
    select * from RETAINIQ.STAGING.stg_subscriptions
),
events as (
    select
        customer_id,
        count(*)                                as total_events,
        count(distinct event_date)              as active_days,
        max(event_date)                         as last_active_date,
        avg(session_duration_min)               as avg_session_duration,
        datediff('day', max(event_date), current_date()) as days_since_last_active,
        count(distinct date_trunc('month', event_date)) as active_months
    from RETAINIQ.STAGING.stg_events
    group by customer_id
),
payments as (
    select
        customer_id,
        count(*)                                as total_payments,
        sum(case when is_failed then 1 else 0 end) as failed_payments,
        round(sum(case when is_failed then 1 else 0 end) / nullif(count(*), 0) * 100, 2) as payment_failure_rate
    from RETAINIQ.STAGING.stg_payments
    group by customer_id
),
support as (
    select
        customer_id,
        count(*)                                as total_tickets,
        avg(satisfaction_score)                 as avg_satisfaction,
        sum(case when priority = 'CRITICAL' then 1 else 0 end) as critical_tickets,
        sum(case when is_resolved = false then 1 else 0 end) as open_tickets
    from RETAINIQ.STAGING.stg_support_tickets
    group by customer_id
),
firmographics as (
    select * from RETAINIQ.STAGING.stg_firmographics
),
final as (
    select
        c.customer_id,
        c.company_name,
        c.industry,
        c.company_size,
        c.acquisition_channel,
        c.plan,
        c.mrr,
        c.country,
        c.nps_score,
        c.onboarding_completed,
        s.is_churned,
        s.churn_reason,
        s.tenure_days,
        s.start_date,
        s.end_date,
        e.total_events,
        e.active_days,
        e.active_months,
        e.last_active_date,
        e.avg_session_duration,
        e.days_since_last_active,
        p.total_payments,
        p.failed_payments,
        p.payment_failure_rate,
        sp.total_tickets,
        sp.avg_satisfaction,
        sp.critical_tickets,
        sp.open_tickets,
        f.funding_stage,
        f.employee_count,
        f.has_data_team,
        f.g2_rating,
        round(
            least(e.days_since_last_active / 180.0 * 40, 40) +
            least(p.payment_failure_rate / 50.0 * 35, 35) +
            least(coalesce(sp.critical_tickets, 0) / 5.0 * 15, 15) +
            least((10 - c.nps_score) / 10.0 * 10, 10)
        , 1) as churn_risk_score,
        case
            when s.is_churned = true then 'CHURNED'
            when e.days_since_last_active > 180 or p.payment_failure_rate > 35 then 'CRITICAL_RISK'
            when e.days_since_last_active > 60 or p.payment_failure_rate > 25 then 'AT_RISK'
            when p.payment_failure_rate > 15 then 'PAYMENT_RISK'
            when e.days_since_last_active > 30 then 'LOW_ENGAGEMENT'
            else 'HEALTHY'
        end as customer_health,
        case
            when s.is_churned = false
                and (e.days_since_last_active > 60 or p.payment_failure_rate > 25) then true
            else false
        end as is_mrr_at_risk
    from customers c
    left join subscriptions s using (customer_id)
    left join events e using (customer_id)
    left join payments p using (customer_id)
    left join support sp using (customer_id)
    left join firmographics f using (customer_id)
)
select * from final
  );

