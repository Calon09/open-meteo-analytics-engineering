with hourly_air_quality as (

    select *
    from {{ ref('stg_air_quality_hourly') }}
    where measured_at is not null

),

daily_rollup as (

    select
        location_id,
        cast(measured_at as date) as air_quality_date,
        count(*) as air_quality_hour_count,
        min(measured_at) as first_measured_at,
        max(measured_at) as last_measured_at,
        avg(pm10) as avg_pm10,
        max(pm10) as max_pm10,
        avg(pm2_5) as avg_pm2_5,
        max(pm2_5) as max_pm2_5,
        avg(carbon_monoxide) as avg_carbon_monoxide,
        max(carbon_monoxide) as max_carbon_monoxide,
        avg(nitrogen_dioxide) as avg_nitrogen_dioxide,
        max(nitrogen_dioxide) as max_nitrogen_dioxide,
        avg(sulphur_dioxide) as avg_sulphur_dioxide,
        max(sulphur_dioxide) as max_sulphur_dioxide,
        avg(ozone) as avg_ozone,
        max(ozone) as max_ozone,
        avg(european_aqi) as avg_european_aqi,
        max(european_aqi) as max_european_aqi

    from hourly_air_quality
    group by 1, 2

)

select
    location_id || '_' || replace(cast(air_quality_date as varchar), '-', '') as air_quality_day_id,
    location_id,
    air_quality_date,
    air_quality_hour_count,
    first_measured_at,
    last_measured_at,
    avg_pm10,
    max_pm10,
    avg_pm2_5,
    max_pm2_5,
    avg_carbon_monoxide,
    max_carbon_monoxide,
    avg_nitrogen_dioxide,
    max_nitrogen_dioxide,
    avg_sulphur_dioxide,
    max_sulphur_dioxide,
    avg_ozone,
    max_ozone,
    avg_european_aqi,
    max_european_aqi

from daily_rollup
