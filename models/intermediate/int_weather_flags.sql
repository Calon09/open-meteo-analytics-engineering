with city_day_weather as (

    select *
    from {{ ref('int_city_day_weather') }}

),

base_flags as (

    select
        *,
        coalesce(rain_mm, 0) > 0
            or coalesce(precipitation_mm, 0) > 0 as is_rainy_day,
        coalesce(precipitation_mm, 0) >= 10 as is_heavy_rain_day,
        coalesce(temperature_max_celsius >= 30, false) as is_hot_day,
        coalesce(temperature_max_celsius >= 35, false) as is_extreme_heat_day,
        coalesce(wind_speed_max_kmh >= 30, false) as is_windy_day,
        coalesce(max_european_aqi >= 60, false) as is_poor_air_quality_day,
        coalesce(temperature_mean_celsius between 18 and 26, false) as is_comfortable_temperature_day

    from city_day_weather

)

select
    *,
    is_comfortable_temperature_day
        and not is_rainy_day
        and not is_windy_day
        and not is_hot_day
        and not is_poor_air_quality_day as is_comfortable_day

from base_flags
