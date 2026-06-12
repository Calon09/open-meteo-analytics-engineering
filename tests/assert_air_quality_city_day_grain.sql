select
    location_id,
    air_quality_date,
    count(*) as row_count

from {{ ref('fct_air_quality_city_day') }}
group by 1, 2
having count(*) > 1
