
  create or replace   view RETAINIQ.STAGING.stg_macro_indicators
  
  
  
  
  as (
    with source as (
    select * from RETAINIQ.RAW.MACRO_INDICATORS
),

renamed as (
    select
        month,
        fed_funds_rate,
        us_gdp_growth_pct,
        saas_valuation_index,
        cpi_inflation_pct,
        tech_layoffs_count,
        vc_funding_index,
        us_unemployment_rate,
        case
            when fed_funds_rate > 4.0 then 'HIGH'
            when fed_funds_rate > 2.0 then 'MEDIUM'
            else 'LOW'
        end                                     as rate_environment,
        case
            when cpi_inflation_pct > 5.0 then 'HIGH'
            when cpi_inflation_pct > 3.0 then 'MEDIUM'
            else 'LOW'
        end                                     as inflation_regime,
        current_timestamp()                     as loaded_at
    from source
)

select * from renamed
  );

