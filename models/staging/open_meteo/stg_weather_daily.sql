with source as (

    select *
    from {{ source('open_meteo_raw', 'raw_weather_daily') }}

),

renamed as (

    select distinct
        cast(location_id as varchar) as location_id,
        cast(city_name as varchar) as city,
        cast(null as varchar) as country,
        cast(latitude as double) as latitude,
        cast(longitude as double) as longitude,
        cast(timezone as varchar) as timezone,
        cast(date as date) as weather_date,
        cast(temperature_2m_max as double) as temperature_max_celsius,
        cast(temperature_2m_min as double) as temperature_min_celsius,
        cast(temperature_2m_mean as double) as temperature_mean_celsius,
        cast(precipitation_sum as double) as precipitation_mm,
        cast(rain_sum as double) as rain_mm,
        cast(snowfall_sum as double) as snowfall_mm,
        cast(wind_speed_10m_max as double) as wind_speed_max_kmh,
        cast(null as double) as wind_gusts_max_kmh

    from source

)

select *
from renamed