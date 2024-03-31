-- 예약자별 예약 생성위치 확인용 쿼리

WITH tmp AS (
  SELECT
    TDDATE,
    callerLog.memberId AS member_id,
    DATETIME(TIMESTAMP_TRUNC(timeMs, SECOND), "Asia/Seoul") AS created_at_kst,
    locationAction.location.lng AS lng,
    locationAction.location.lat AS lat,
  FROM
    `socar_server_2.SAVE_LOCATION_ACTION_LOG`
  WHERE
    locationAction.viewAction="RESERVED_CAR_RENTAL"
    AND fullAccuracyLocationLog.isFullAccuracyLocation IS TRUE
    AND TIMESTAMP_TRUNC(timeMs, DAY) BETWEEN TIMESTAMP("2022-01-01") AND TIMESTAMP("2022-12-31")
),

rv AS (
  SELECT
    id AS reservation_id,
    member_id,
    DATETIME(created_at, "Asia/Seoul") AS created_at_kst,
    zone_id
  FROM `tianjin_replica.reservation_info`
  WHERE
    member_imaginary IN (0, 9)
    AND state IN (1,2,3)
    AND DATE(created_at, 'Asia/Seoul') BETWEEN DATE('2022-01-01') AND DATE('2022-12-31')
),

loc2022 AS (
  SELECT
    rv.reservation_id as rid,
    rv.member_id  as mid,
    cast(rv.created_at_kst as datetime) as created_at,
    rv.zone_id,
    tmp.lat,
    tmp.lng,
    z.lat as zone_lat, 
    z.lng as zone_lng
  FROM rv
  LEFT JOIN tmp
  USING (member_id, created_at_kst)
  LEFT JOIN `tianjin_replica.carzone_info` z ON rv.zone_id = z.id
  WHERE tmp.lat is not null 
  AND z.region1 = '제주특별자치도'
  AND z.state = 1
),

loc2023 AS (
  SELECT
    date as rdate,
    reservation_id as rid,
    member_id as mid,
    zone_id,
    zone_lat, zone_lng,
    reservation_created_lng as lng,
    reservation_created_lat as lat,
    cast(reservation_created_at as datetime) as created_at,
  FROM `socar_data_queries_zone_stat_viz_mart.zsv_obt` a
  LEFT JOIN `tianjin_replica.carzone_info` z ON a.zone_id = z.id
  WHERE extract(year FROM reservation_created_at) = 2023
  AND reservation_created_lng is not null
  AND z.region1 = '제주특별자치도'
  AND z.state = 1
)

SELECT * FROM loc2022
UNION ALL
SELECT rid, mid, created_at, zone_id, lat, lng, zone_lat, zone_lng FROM loc2023
ORDER BY created_at desc

