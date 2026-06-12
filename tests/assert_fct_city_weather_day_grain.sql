select
    location_id,
    weather_date,
    count(*) as row_count

from {{ ref('fct_city_weather_day') }}
group by 1, 2
having count(*) > 1
