-- 매출 정산에 활용하기 위한 지역별 매출/할인 계산 쿼리
-- started_at을 기준으로 날짜 가져옮
WITH rb AS(
    SELECT 
        a.year, a.month, a.day, a.hour, a.region, a.area, a.start_addr, a.riding_id, a.bike_id, a.billing_id, a.user_id, -- 결제 유저 기본 정보
        extract(epoch FROM a.duration::INTERVAL)/ 60 as duration -- 이용시간 계산
        a.distance, a.fee,
        b.charge, b.amount, b.income, b.pg, b.insure,
        b.discounts[1] as discounts1, b.discounts[2] as discounts2, b.discounts[3] as discounts3, b.discounts[4] as discounts4,
        b.discounts[5] as discounts5, b.discounts[6] as discounts6, b.discounts[7] as discounts7, b.discounts[8] as discounts8,
        b.discounts[9] as discounts9, b.discounts[10] as discounts10,
        b.surcharges[1] as surcharges
    FROM 
        (
            SELECT 
                year, month, day, hour, 
                a.name as region, b.name as area, a.start_addr, 
                a.riding_id, a.bike_id, a.billing_id, a.user_id, a.duration, a.distance, a.fee
            FROM
                (
                    SELECT 
                        a.year, a.month, a.day, a.hour, b.name, a.area, a.start_addr, 
                        a.riding_id, a.bike_id, a.billing_id, a.user_id, a.duration, a.distance, a.fee
                    FROM
                        (
                            SELECT
                                extract(year FROM started_at AT TIME ZONE 'kst') as year, 
                                extract(month FROM started_at AT TIME ZONE 'kst') as month,
                                extract(day FROM started_at AT TIME ZONE 'kst') as day,
                                extract(hour FROM started_at AT TIME ZONE 'kst') as hour,
                                a.region, a.area, a.start_addr,
                                a.id as riding_id, a.bike_id, a.billing_id, a.user_id,
                                a.duration, a.distance, a.fee
                            FROM public.riding a LEFT JOIN public.bike b ON a.bike_id = b.id
                            WHERE a.status = 10 AND b.is_usable is true) a -- 라이딩 정보
                    LEFT JOIN public.geo_region b ON a.region = b.code) a -- 라이딩 정보에 지역 정보 추가
            LEFT JOIN public.geo_area b ON a.area = b.code) a LEFT JOIN ( 
                                                                            SELECT
                                                                                extract(year FROM created_at AT TIME ZONE 'kst') as year, 
                                                                                extract(month FROM created_at AT TIME ZONE 'kst') as month,
                                                                                extract(day FROM created_at AT TIME ZONE 'kst') as day,
                                                                                extract(hour FROM created_at AT TIME ZONE 'kst') as hour,
                                                                                id as billing_id, user_id,

                                                                                CASE WHEN status = -1 THEN '결제 처리중'
                                                                                    WHEN status = 0 THEN '결제대기중'
                                                                                    WHEN status = 1 THEN '결제실패'
                                                                                    WHEN status = 2 THEN '결제완료'
                                                                                    WHEN status = 3 THEN '부분완료'
                                                                                    WHEN status = 4 THEN '전체환불됨'
                                                                                    WHEN status = 10 THEN '무효화됨' END as status,

                                                                                CASE WHEN payment = 0 THEN '일반이용'
                                                                                    WHEN payment = 1 THEN '정기권/멤버쉽'
                                                                                    WHEN payment = 2 THEN '상품'
                                                                                    WHEN payment = 3 THEN '라이딩 예약' END as payment,
                                                                                charge, amount, income, pg, insure, discounts, surcharges
                                                                            FROM public.billing
                                                                            WHERE status = 2 AND payment = 0) b -- product 타입별 할인 정보
                ON a.billing_id = b.billing_id 
)

SELECT 
    year, month, day, region, area, start_addr,
    count(riding_id) as riding_cnt,
    count(distinct bike_id) as bike_cnt,
    count(distinct user_id) as user_cnt,
    round(sum(duration)) as duration, sum(distance) as distance, sum(fee) as fee,
    sum(charge) as charge, sum(amount) as amount, sum(income) as income, sum(pg) as pg, sum(insure) as insure, -- 결제 매출 지표
    sum(discounts1 + discounts2 + discounts3 + discounts4 + discounts5 + discounts6 + discounts7 + discounts8 + discounts9 + discounts10) as discount_agg, -- 결제 할인율 정보
    sum(surcharges) as surcharges 
FROM rb
WHERE month in (7,8)
GROUP BY year, month, day, region, area, start_addr
ORDER BY year desc, month desc, day desc