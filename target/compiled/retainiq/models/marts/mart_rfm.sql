with customers as (
    select * from RETAINIQ.STAGING.stg_customers
),

subscriptions as (
    select * from RETAINIQ.STAGING.stg_subscriptions
),

events as (
    select
        customer_id,
        max(event_date)                         as last_event_date,
        count(*)                                as total_events,
        count(distinct date_trunc('month', 
            event_date))                        as active_months
    from RETAINIQ.STAGING.stg_events
    group by customer_id
),

rfm_base as (
    select
        c.customer_id,
        c.company_name,
        c.industry,
        c.company_size,
        c.plan,
        c.mrr,
        c.acquisition_channel,
        s.is_churned,
        s.tenure_days,
        datediff('day', e.last_event_date, 
            current_date())                     as recency_days,
        e.total_events                          as frequency,
        c.mrr                                   as monetary,
        e.active_months
    from customers c
    left join subscriptions s using (customer_id)
    left join events e using (customer_id)
),

rfm_scores as (
    select
        *,
        ntile(5) over (
            order by recency_days desc)         as r_score,
        ntile(5) over (
            order by frequency asc)             as f_score,
        ntile(5) over (
            order by monetary asc)              as m_score
    from rfm_base
),

final as (
    select
        customer_id,
        company_name,
        industry,
        company_size,
        plan,
        mrr,
        acquisition_channel,
        is_churned,
        tenure_days,
        recency_days,
        frequency,
        monetary,
        active_months,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score)           as rfm_total,
        concat(r_score, f_score, m_score)       as rfm_segment,
        case
            when r_score >= 4 
                and f_score >= 4 
                and m_score >= 4                then 'CHAMPION'
            when r_score >= 3 
                and f_score >= 3               then 'LOYAL'
            when r_score >= 4 
                and f_score <= 2               then 'NEW_CUSTOMER'
            when r_score <= 2 
                and f_score >= 3 
                and m_score >= 3               then 'AT_RISK'
            when r_score <= 2 
                and f_score <= 2               then 'LOST'
            else                                    'POTENTIAL'
        end                                     as rfm_label
    from rfm_scores
)

select * from final