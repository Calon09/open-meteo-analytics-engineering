select
    location_id,
    count(*) as row_count

from {{ ref('dim_location') }}
group by 1
having count(*) > 1
