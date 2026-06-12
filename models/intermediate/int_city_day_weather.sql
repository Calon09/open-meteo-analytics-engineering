with weather_daily as (

    select *
    from {{ ref('stg_weather_daily') }}
    where weather_date is not null
      and temperature_mean_celsius is not null

),

locations as (

    select *
    from {{ ref('stg_locations') }}

),

air_quality_daily as (

    select *
    from {{ ref('int_air_quality_daily') }}

)

select
    weather_daily.location_id || '_' || replace(cast(weather_daily.weather_date as varchar), '-', '') as city_day_weather_id,
    weather_daily.location_id,
    weather_daily.weather_date,
    coalesce(locations.city, weather_daily.city) as city,
    locations.country,
    locations.country_code,
    locations.admin_region,
    coalesce(locations.latitude, weather_daily.latitude) as latitude,
    coalesce(locations.longitude, weather_daily.longitude) as longitude,
    coalesce(locations.timezone, weather_daily.timezone) as timezone,
    weather_daily.temperature_max_celsius,
    weather_daily.temperature_min_celsius,
    weather_daily.temperature_mean_celsius,
    weather_daily.precipitation_mm,
    weather_daily.rain_mm,
    weather_daily.snowfall_mm,
    weather_daily.wind_speed_max_kmh,
    weather_daily.wind_gusts_max_kmh,
    air_quality_daily.air_quality_day_id,
    air_quality_daily.air_quality_hour_count,
    air_quality_daily.avg_pm10,
    air_quality_daily.max_pm10,
    air_quality_daily.avg_pm2_5,
    air_quality_daily.max_pm2_5,
    air_quality_daily.avg_carbon_monoxide,
    air_quality_daily.max_carbon_monoxide,
    air_quality_daily.avg_nitrogen_dioxide,
    air_quality_daily.max_nitrogen_dioxide,
    air_quality_daily.avg_sulphur_dioxide,
    air_quality_daily.max_sulphur_dioxide,
    air_quality_daily.avg_ozone,
    air_quality_daily.max_ozone,
    air_quality_daily.avg_european_aqi,
    air_quality_daily.max_european_aqi,
    air_quality_daily.air_quality_date is not null as has_air_quality_data

from weather_daily
left join locations
    on weather_daily.location_id = locations.location_id
left join air_quality_daily
    on weather_daily.location_id = air_quality_daily.location_id
    and weather_daily.weather_date = air_quality_daily.air_quality_date
