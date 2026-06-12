select
    air_quality_day_id as air_quality_city_day_id,
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
    max_european_aqi,
    coalesce(max_european_aqi >= 60, false) as is_poor_air_quality_day

from {{ ref('int_air_quality_daily') }}
