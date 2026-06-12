with city_weather_day as (

    select *
    from {{ ref('fct_city_weather_day') }}

),

locations as (

    select *
    from {{ ref('dim_location') }}

),

aggregated as (

    select
        location_id,
        min(weather_date) as first_weather_date,
        max(weather_date) as last_weather_date,
        count(*) as total_days,
        round(avg(temperature_mean_celsius), 2) as avg_temperature_celsius,
        round(avg(temperature_max_celsius), 2) as avg_temperature_max_celsius,
        round(avg(temperature_min_celsius), 2) as avg_temperature_min_celsius,
        round(coalesce(sum(precipitation_mm), 0), 2) as total_precipitation_mm,
        round(avg(precipitation_mm), 2) as avg_precipitation_mm,
        round(avg(wind_speed_max_kmh), 2) as avg_wind_speed_max_kmh,
        round(avg(avg_european_aqi), 2) as avg_european_aqi,
        sum(case when is_rainy_day then 1 else 0 end) as rainy_days,
        sum(case when is_heavy_rain_day then 1 else 0 end) as heavy_rain_days,
        sum(case when is_hot_day then 1 else 0 end) as hot_days,
        sum(case when is_extreme_heat_day then 1 else 0 end) as extreme_heat_days,
        sum(case when is_windy_day then 1 else 0 end) as windy_days,
        sum(case when is_poor_air_quality_day then 1 else 0 end) as poor_air_quality_days,
        sum(case when is_comfortable_temperature_day then 1 else 0 end) as comfortable_temperature_days,
        sum(case when is_comfortable_day then 1 else 0 end) as comfortable_days,
        sum(case when has_air_quality_data then 1 else 0 end) as air_quality_days

    from city_weather_day
    group by 1

),

rates as (

    select
        *,
        round(cast(rainy_days as double) / nullif(total_days, 0), 4) as rainy_day_rate,
        round(cast(heavy_rain_days as double) / nullif(total_days, 0), 4) as heavy_rain_day_rate,
        round(cast(hot_days as double) / nullif(total_days, 0), 4) as hot_day_rate,
        round(cast(extreme_heat_days as double) / nullif(total_days, 0), 4) as extreme_heat_day_rate,
        round(cast(windy_days as double) / nullif(total_days, 0), 4) as windy_day_rate,
        round(cast(comfortable_temperature_days as double) / nullif(total_days, 0), 4) as comfortable_temperature_day_rate,
        round(cast(comfortable_days as double) / nullif(total_days, 0), 4) as comfortable_day_rate,
        case
            when air_quality_days = 0 then 0
            else round(cast(poor_air_quality_days as double) / air_quality_days, 4)
        end as poor_air_quality_day_rate

    from aggregated

),

scored as (

    select
        *,
        round(
            greatest(
                0,
                least(
                    100,
                    100 * (
                        comfortable_day_rate * 0.45
                        + (1 - rainy_day_rate) * 0.20
                        + (1 - hot_day_rate) * 0.15
                        + (1 - windy_day_rate) * 0.10
                        + (1 - poor_air_quality_day_rate) * 0.10
                    )
                )
            ),
            2
        ) as comfort_score

    from rates

)

select
    scored.location_id,
    locations.city,
    locations.country,
    locations.country_code,
    locations.admin_region,
    locations.latitude,
    locations.longitude,
    locations.timezone,
    scored.first_weather_date,
    scored.last_weather_date,
    scored.total_days,
    scored.air_quality_days,
    scored.avg_temperature_celsius,
    scored.avg_temperature_max_celsius,
    scored.avg_temperature_min_celsius,
    scored.total_precipitation_mm,
    scored.avg_precipitation_mm,
    scored.avg_wind_speed_max_kmh,
    scored.avg_european_aqi,
    scored.rainy_days,
    scored.heavy_rain_days,
    scored.hot_days,
    scored.extreme_heat_days,
    scored.windy_days,
    scored.poor_air_quality_days,
    scored.comfortable_temperature_days,
    scored.comfortable_days,
    scored.rainy_day_rate,
    scored.heavy_rain_day_rate,
    scored.hot_day_rate,
    scored.extreme_heat_day_rate,
    scored.windy_day_rate,
    scored.poor_air_quality_day_rate,
    scored.comfortable_temperature_day_rate,
    scored.comfortable_day_rate,
    scored.comfort_score

from scored
left join locations
    on scored.location_id = locations.location_id
