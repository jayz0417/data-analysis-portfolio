-- 센터별 운영 성과지표
-- Holistics의 대시보드상 일레클 전체 센터, 센터별, 전체 모델, 모델의 일별 성과를 분석하기 위한 쿼리

#standardSQL
WITH bike_history2 AS (
    SELECT date, hour, bike_type, bike_status, vendor, sn,
    bike_region, bike_area, h3_area_name, h3_district_name,
    count(distinct bike_id) as bike_cnt
    FROM elecle_slave.tf_bike_snapshot
    WHERE date BETWEEN current_date('Asia/Seoul') -28 ANd current_date('Asia/Seoul') -1 AND is_active = true
    GROUP BY date, hour, bike_type, bike_status, vendor, sn, bike_region, bike_area, h3_area_name, h3_district_name
),

bike_base AS (
    SELECT
    -- 날짜
    extract(isoyear FROM date) as year, extract(month FROM date) as month, extract(isoweek FROM date) as week, date,
    -- 지역정보
    r.title as city, r.center_name as center,
    r.area_name as area,
    -- 기기 타입 분류
    CASE WHEN bike_type = 1 THEN '자전거'
         WHEN bike_type = 2 THEN '킥보드' END as bike_type,
    -- SN 넘버로 모델 구분
    -- 네오 = 1011
    -- 플러스 = 1013
    -- 플러스 신형 1013 AND sn > 10130999
    -- 플러스 구형 1013 AND sn <= 10130999
    CASE WHEN substr(sn, 1, 4) = '1010' THEN '클래식'
         WHEN substr(sn, 1, 4) = '1011' THEN '네오'
         WHEN substr(sn, 1, 4) = '1013' AND cast(sn AS int) > 10130999 THEN '플러스_신형'
         WHEN substr(sn, 1, 4) = '1013' AND cast(sn AS int) <= 10130999 THEN '플러스_구형' END as vendor,
    bike_status,
    -- bike_status 분류
    CASE WHEN bike_status in ('BNB', 'BRD', 'LRD', 'BAV') THEN '이용가능'
    WHEN bike_status in ('BB', 'LB', 'BP', 'LP') THEN '관리중'
    WHEN bike_status in ('LNB', 'BNP', 'LNP', 'LAV') THEN '현장조치대기' END as bike_status_tf, bike_cnt
    FROM bike_history2 tbh2 LEFT JOIN management.region r ON tbh2.bike_area = r.area_cd
    WHERE bike_type = 1 AND date > '2020-01-01'
),

bike_count AS (
    SELECT year, month, week, date,
    CASE WHEN city is null THEN '기타' ELSE city END as city,
    CASE WHEN center is null THEN '기타' ELSE center END as center,
    bike_type, vendor, bike_status_tf,
    (sum(bike_cnt)/24) as bike_cnt
    FROM bike_base
    GROUP BY year, month, week, date, city, center, area, bike_type, vendor, bike_status_tf
    ORDER BY year, month, week, date, city, center, area, bike_type, vendor, bike_status_tf
),

bike_op AS (
    SELECT year, month, week, date, center, vendor,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) + CASE WHEN sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) is null THEN 0 ELSE sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) END as on_field_bike,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) as av_bike,
    sum(CASE WHEN bike_status_tf in ('이용가능', '관리중', '현장조치대기') THEN bike_cnt END) as own_bike,
    FROM bike_count
    GROUP BY year, month, week, date, center, vendor
), -- 센터별/운영기기 모델별 성과지표

bike_op_total AS (
    SELECT year, month, week, date, center,
    "전체" as vendor,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) + CASE WHEN sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) is null THEN 0 ELSE sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) END as on_field_bike,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) as av_bike,
    sum(CASE WHEN bike_status_tf in ('이용가능', '관리중', '현장조치대기') THEN bike_cnt END) as own_bike,
    FROM bike_count
    GROUP BY year, month, week, date, center, vendor
), -- 센터별 모든 운영기기의 성과지표, 센터별 전체 모델의 운영 현황 분석용

bike_op_total2 AS (
    SELECT year, month, week, date, 
    "전체" as center,
    "전체" as vendor,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) + CASE WHEN sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) is null THEN 0 ELSE sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) END as on_field_bike,
    sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) as av_bike,
    sum(CASE WHEN bike_status_tf in ('이용가능', '관리중', '현장조치대기') THEN bike_cnt END) as own_bike,
    FROM bike_count
    GROUP BY year, month, week, date, center, vendor
), -- 모든 센터의 모든 운영기기 성과지표, 전체 센터의 전체 모델별 운영 현황 분석용

bike_union AS (
    SELECT * FROM bike_op
    UNION ALL
    SELECT * FROM bike_op_total
    UNION ALL
    SELECT * FROM bike_op_total2
)

SELECT
    year, month, week, date, center, vendor,
    on_field_bike, av_bike, own_bike,
    av_bike/own_bike as availability
FROM bike_union
WHERE vendor = "전체" AND center not in ('기타', '수원센터')
ORDER BY date desc, center