with source as (

    select *
    from {{ source('open_meteo_raw', 'raw_locations') }}

),

renamed as (

    select distinct
        cast(location_id as varchar) as location_id,
        cast(city_name as varchar) as city,
        cast(country as varchar) as country,
        cast(country_code as varchar) as country_code,
        cast(latitude as double) as latitude,
        cast(longitude as double) as longitude,
        cast(timezone as varchar) as timezone,
        cast(elevation as double) as elevation_meters,
        cast(admin1 as varchar) as admin_region

    from source

)

select *
from renamed