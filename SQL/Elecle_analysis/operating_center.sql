-- 센터별 운영 현황
-- 각 현장 센터별 성과를 집계하기 위한 쿼리
-- 센터 = 지역별 기기 운영팀(현장관리, 유지보수)

#standardSQL -- Holistics 쿼리 워킹시, 빅쿼리를 불러오기 위해 스탠다드 문법임을 명시

WITH bike_history2 AS (
    SELECT 
        date, hour, bike_type, bike_status, vendor, sn,
        bike_region, bike_area, h3_area_name, h3_district_name,
        count(distinct bike_id) as bike_cnt
    FROM elecle_slave.tf_bike_snapshot
    WHERE date BETWEEN current_date('Asia/Seoul') -28 ANd current_date('Asia/Seoul') -1 AND is_active = true
    GROUP BY date, hour, bike_type, bike_status, vendor, sn, bike_region, bike_area, h3_area_name, h3_district_name
), -- 최근 28일(4주) 동안 운영된 지역별 시간대별 기기 대수

bike_base AS (
    SELECT
        -- 날짜
        extract(isoyear FROM date) as year, extract(month FROM date) as month, extract(isoweek FROM date) as week, date,
        -- 기기 타입 분류
        CASE WHEN bike_type = 1 THEN '자전거'
            WHEN bike_type = 2 THEN '킥보드' END as bike_type,
        -- SN 넘버로 모델 구분
        -- 네오 = 1011
        -- 플러스 = 1013
        -- 플러스 신형 1013 AND sn > 10130999
        -- 플러스 구형 1013 AND sn <= 10130999
        bike_status,
        -- bike_status 분류
        CASE WHEN bike_status in ('BNB', 'BRD', 'LRD', 'BAV') THEN '이용가능'
            WHEN bike_status in ('BB', 'LB', 'BP', 'LP') THEN '관리중'
            WHEN bike_status in ('LNB', 'BNP', 'LNP', 'LAV') THEN '현장조치대기' END as bike_status_tf, 
        bike_cnt
    FROM bike_history2
    WHERE bike_type = 1 AND date > '2021-01-01'
), -- 기본 바이크 정보 구분

bike_count AS (
    SELECT
        year, month, week, date,
        bike_type, bike_status_tf,
        (sum(bike_cnt)/24) as bike_cnt
    FROM bike_base
    GROUP BY year, month, week, date, bike_type, bike_status_tf
    ORDER BY year, month, week, date, bike_type, bike_status_tf
), -- 일별 기기 대수

bike_op_total AS (
    SELECT 
        year, month, week, date,
        "전체" as center,
        "전체" as vendor,
        sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) + CASE WHEN sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) is null THEN 0 ELSE sum(CASE WHEN bike_status_tf = '현장조치대기' THEN bike_cnt END) END as on_field_bike,
        sum(CASE WHEN bike_status_tf = '이용가능' THEN bike_cnt END) as av_bike,
        sum(CASE WHEN bike_status_tf in ('이용가능', '관리중', '현장조치대기') THEN bike_cnt END) as own_bike,
    FROM bike_count
    GROUP BY year, month, week, date, center, vendor
) -- 기기의 상태별 운영대수

SELECT
    year, month, week, date, center, vendor,
    on_field_bike, -- 배치된 모든 기기 대수
    av_bike,  -- 배치된 기기중 이용 가능한 기기 대수
    own_bike, -- 보유한 모두 기기 대수(센터 입고 포함)
    av_bike/own_bike as availability, -- 가용률 / 센터에서 이용 가능한 기기를 만들어낸 대수 / 센터별 핵심 성과지표
    on_field_bike/own_bike as repair_rating, -- 수리율 / 센터에서 출고된 기기 대수 / 센터별 핵심 성과지표(유지보수)
    av_bike/on_field_bike as onsite_rating -- 이용 가능률 // 센터별 핵심 성과지표(현장관리)
FROM bike_op_total
ORDER BY date desc, center