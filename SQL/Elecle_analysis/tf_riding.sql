-- riding 로그데이터로부터 분석용으로 가공된 tf_riding 쿼리

SELECT 
    --started_at,
    riding.id as id, 
    DATETIME(riding.created_at, 'Asia/Seoul') as created_time, 
    DATETIME(riding.modified_at, 'Asia/Seoul') as modified_time, 
    DATE(riding.started_at, 'Asia/Seoul') as start_date, 
    DATE(riding.ended_at, 'Asia/Seoul') as end_date, 
    DATETIME(riding.reserved_at, 'Asia/Seoul') as reserve_time, 
    DATETIME(riding.started_at, 'Asia/Seoul') as start_time, 
    DATETIME(riding.ended_at, 'Asia/Seoul') as end_time,
    bike_id,
    bike_type, 
    riding.region as riding_region, 
    riding.region as region , 
    riding.area as riding_area, 
    riding.area as area, 
    organization_id,
    organization_id as organization_type, 
    user_id, billing_id, distance, fee, 
    riding.status as status, 
    FLOOR(duration) as used_min, 
    rating, user_comment, 
    EXTRACT(DAYOFWEEK FROM DATE(riding.started_at, 'Asia/Seoul')) as day_of_week, 
    CASE WHEN EXTRACT(DAYOFWEEK FROM DATE(riding.started_at, 'Asia/Seoul')) >= 2 AND EXTRACT(DAYOFWEEK FROM DATE(riding.started_at, 'Asia/Seoul')) <= 6 THEN 'weekday' ELSE 'weekend' END as weekday, 
    EXTRACT(HOUR FROM DATETIME(riding.started_at, 'Asia/Seoul')) AS start_hour, 
    EXTRACT(HOUR FROM DATETIME(ended_at, 'Asia/Seoul')) AS end_hour, 
    ST_GEOGFROMGEOJSON(start_point) AS start_location, 
    ST_GEOGFROMGEOJSON(end_point) AS end_location, 
    start_addr, 
    end_addr, 
    riding.extra, 
    parking_rack, 
    did_take_shot, 
    return_photo, 
    finish_type, 
    CASE WHEN organization_id is not null THEN 1
         WHEN JSON_EXTRACT_SCALAR(riding.extra, '$.subscription_purchase_id') is not null OR JSON_EXTRACT_SCALAR(riding.extra, '$.riding_pass_id') is not null OR JSON_EXTRACT_SCALAR(riding.extra, '$.applied_pass_id') is not null
            THEN 2 
         WHEN crowd_task.id is not null THEN 3
         ELSE 0 END as riding_type, 
    CASE WHEN JSON_EXTRACT_SCALAR(riding.extra, '$.applied_purchase_id') is not null THEN true ELSE false END AS is_rent_free -- 무료이용권
FROM `elecle-9be54.mainstream.riding` as riding LEFT JOIN `elecle-9be54.elecle_slave.crowd_task` as crowd_task ON riding.id = crowd_task.riding_id