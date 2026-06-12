select *

from {{ ref('fct_city_weather_day') }}
where temperature_mean_celsius < -50
   or temperature_mean_celsius > 60
   or temperature_max_celsius < temperature_min_celsius
   or precipitation_mm < 0
   or rain_mm < 0
   or snowfall_mm < 0
   or wind_speed_max_kmh < 0
   or avg_european_aqi < 0
   or max_european_aqi > 500
