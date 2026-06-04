with source as (

    select *
    from {{ source('open_meteo_raw', 'raw_air_quality_hourly') }}

),

renamed as (

    select distinct
        cast(location_id as varchar) as location_id,
        cast(city_name as varchar) as city,
        cast(null as varchar) as country,
        cast(latitude as double) as latitude,
        cast(longitude as double) as longitude,
        cast(timezone as varchar) as timezone,
        cast(timestamp as timestamp) as measured_at,
        cast(pm10 as double) as pm10,
        cast(pm2_5 as double) as pm2_5,
        cast(carbon_monoxide as double) as carbon_monoxide,
        cast(nitrogen_dioxide as double) as nitrogen_dioxide,
        cast(null as double) as sulphur_dioxide,
        cast(ozone as double) as ozone,
        cast(european_aqi as integer) as european_aqi,
        cast(extracted_at as timestamp) as extracted_at

    from source

)

select *
from renamed