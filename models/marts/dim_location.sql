select distinct
    location_id,
    city,
    country,
    country_code,
    admin_region,
    latitude,
    longitude,
    timezone,
    elevation_meters

from {{ ref('stg_locations') }}
