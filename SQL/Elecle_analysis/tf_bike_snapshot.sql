-- 로그데이터로부터 bike의 시간대별 배터리 정보를 알수 있는 tf_bike_snapshot 쿼리
SELECT 
    A.* except(region, area, organization), 
    region as bike_region, 
    area as bike_area, 
    organization as organization_id, 
    type as bike_type, 
    DATETIME(timestamp, 'Asia/Seoul') as time, 
    DATE(timestamp, 'Asia/Seoul') as date, 
    extract(hour FROM timestamp AT TIME ZONE 'Asia/Seoul') as hour, 
    udf.get_h3_area(ST_GEOGFROMGEOJSON(location)) as h3_area_name, 
    udf.get_h3_district(ST_GEOGFROMGEOJSON(location)) as h3_district_name, 
    CASE WHEN (status = 0 and leftover > threshold) then 'BNB'
         WHEN (status = 1 and leftover > threshold) then 'BNP'
         WHEN (status = 2 and leftover > threshold) then 'BB'
         WHEN (status = 3 and leftover > threshold) then 'BP'
         WHEN (status = 4 and leftover > threshold) then 'BRD'
         WHEN (status = 5 and leftover > threshold) then 'BAV'
         WHEN (status = 0 and leftover <= threshold) then 'LNB'
         WHEN (status = 1 and leftover <= threshold) then 'LNP'
         WHEN (status = 2 and leftover <= threshold) then 'LB'
         WHEN (status = 3 and leftover <= threshold) then 'LP'
         WHEN (status = 4 and leftover <= threshold) then 'LRD' ELSE 'LAV' END as bike_status,
FROM mainstream.bike_snapshot as A INNER JOIN `elecle-9be54.elecle_slave.tf_bike` as B ON A.bike_id = B.id
WHERE B.is_usable is true OR (B.is_usable is false AND DATE(A.timestamp, 'Asia/Seoul') < B.date_of_death) and A.is_active is true
