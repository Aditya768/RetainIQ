-- ============================================================
-- RetainIQ: Rolling 30-Day Engagement Scoring
-- Purpose: Calculate a rolling engagement score per customer
--          to identify disengagement trends before churn
-- Technique: Window functions + rolling aggregations
-- ============================================================

with daily_events as (
    select
        customer_id,
        event_date,
        count(*)                                     as daily_events,
        sum(session_duration_min)                    as daily_session_mins,
        count(distinct event_type)                   as unique_features_used
    from {{ ref('stg_events') }}
    group by 1, 2
),

rolling_engagement as (
    select
        customer_id,
        event_date,
        daily_events,
        daily_session_mins,
        unique_features_used,

        -- Rolling 30-day metrics
        sum(daily_events) over (
            partition by customer_id
            order by event_date
            rows between 29 preceding and current row
        )                                            as rolling_30d_events,

        avg(daily_session_mins) over (
            partition by customer_id
            order by event_date
            rows between 29 preceding and current row
        )                                            as rolling_30d_avg_session,

        count(distinct event_date) over (
            partition by customer_id
            order by event_date
            rows between 29 preceding and current row
        )                                            as rolling_30d_active_days,

        -- Rolling 7-day metrics
        sum(daily_events) over (
            partition by customer_id
            order by event_date
            rows between 6 preceding and current row
        )                                            as rolling_7d_events,

        -- Week over week change
        sum(daily_events) over (
            partition by customer_id
            order by event_date
            rows between 6 preceding and current row
        ) - sum(daily_events) over (
            partition by customer_id
            order by event_date
            rows between 13 preceding and 7 preceding
        )                                            as wow_events_change

    from daily_events
),

-- Engagement score (0-100)
engagement_scored as (
    select
        *,
        round(
            least(rolling_30d_active_days / 20.0 * 40, 40) +
            least(rolling_30d_events / 100.0 * 35, 35) +
            least(rolling_30d_avg_session / 30.0 * 25, 25)
        , 1)                                         as engagement_score,

        -- Trend flag
        case
            when wow_events_change > 5               then 'IMPROVING'
            when wow_events_change < -5              then 'DECLINING'
            else                                          'STABLE'
        end                                          as engagement_trend

    from rolling_engagement
)

select
    e.*,
    s.is_churned,
    s.plan,
    c.industry,
    c.company_size
from engagement_scored e
left join {{ ref('stg_subscriptions') }} s  using (customer_id)
left join {{ ref('stg_customers') }} c      using (customer_id)
order by customer_id, event_date