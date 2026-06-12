select *

from {{ ref('mart_city_weather_summary') }}
where location_id is null
   or city is null
   or total_days is null
   or total_days <= 0
   or comfort_score is null
   or comfort_score < 0
   or comfort_score > 100
