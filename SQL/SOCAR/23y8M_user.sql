-- 23y 8M 유저분석용 쿼리

CREATE TEMP FUNCTION set_region(zone_id any TYPE) AS (
  CASE WHEN zone_id IN (737, 12689, 17046, 110, 2819, 2820, 8743, 8744, 10978, 11456, 13744, 13881, 14264, 15322, 16619, 16620, 17020, 17212, 17270, 17378, 10652, 2574, 5828, 8113, 14217, 17053, 17054, 17184, 17145, 12236, 12362, 12583, 14697, 12929, 12930, 17996, 18202, 18203) THEN '공항주변'
       WHEN zone_id IN (10654, 2230, 16618, 17154, 14451, 12703, 18269) THEN '구서귀포'
       WHEN zone_id IN (2341, 2629, 4874, 12661, 11453, 10490, 14430, 14518, 14520, 15304, 16621, 16898, 17465, 114, 14167, 17208, 651, 18204, 18205) THEN '구제주'
       WHEN zone_id IN (879, 14420, 7906, 12762, 13657, 14943, 17196, 17463) THEN '신서귀포'
       WHEN zone_id IN (3967, 3969, 10892, 11165, 12538, 12959, 12858, 12857, 13400, 7288, 11587, 13969, 10391, 12521, 12812, 14757, 16265, 4504, 8539, 8548, 8741, 11884, 13581, 13597, 14361, 14554, 15397, 16363, 16365, 16997, 17185, 13818, 17836, 18151, 17777, 18206) THEN '외곽'
       WHEN zone_id IN (17209) THEN '공항앞'
       WHEN zone_id IN (5894, 12636, 16126, 246, 13606, 16321, 18261) THEN '중문'
       WHEN zone_id IN (105, 9890) THEN '제주공항' ELSE cast(zone_id as string) END
); ## 마지막 업데이트 2023.08.02

WITH base AS (
  SELECT
    r.member_id, count(r.id) as rev_cnt
  FROM `tianjin_replica.reservation_info` r
  WHERE r.state IN (3) AND r.member_imaginary IN (0, 9) AND zone_id IN (8539, 8548, 11884, 12762, 4504, 8744, 15322, 17378, 10490, 12812)
  GROUP BY r.member_id
),

base2 AS (
  SELECT
    member_id, max(rev_rank) as max_rank
  FROM (
    SELECT
      r.member_id, r.zone_id,
      row_number() OVER (partition by member_id order by r.end_at) as rev_rank,
    FROM `tianjin_replica.reservation_info` r  
    WHERE r.state IN (3) AND r.member_imaginary IN (0, 9) AND zone_id IN (8539, 8548, 11884, 12762, 4504, 8744, 15322, 17378, 10490, 12812)
  )
  GROUP BY member_id
),

base3 AS (
  SELECT
    r.member_id, r.zone_id,
    row_number() OVER (partition by member_id order by r.end_at) as rev_rank,
  FROM `tianjin_replica.reservation_info` r  
  WHERE r.state IN (3) AND r.member_imaginary IN (0, 9) AND zone_id IN (8539, 8548, 11884, 12762, 4504, 8744, 15322, 17378, 10490, 12812)
  ),

base4 AS (
  SELECT
    b2.member_id, b3.zone_id, z.zone_name, b3.rev_rank 
  FROM base2 b2 LEFT JOIN base3 b3 ON b2.member_id = b3.member_id ANd b2.max_rank = b3.rev_rank
                LEFT JOIN `tianjin_replica.carzone_info` z ON b3.zone_id = z.id
),

base_calc AS (
  SELECT 
  r.id as reservation_id,
  r.member_id,
  set_region(r.zone_id) as part,
  r.zone_id, z.zone_name,

  CASE WHEN m.member_type = "P" THEN "개인"
        WHEN m.member_type = "C" THEN '법인' ELSE m.member_type END as member_type,  ## 회원 구분
  m.primary_area, ## 자주 이용하는 지역

  CASE WHEN r.age BETWEEN 20 AND 29 THEN '20s'
        WHEN r.age >= 30 THEN '30s' ELSE 'ETC' END as age_type, ## 연령

  CASE WHEN b.rev_cnt <= 3 THEN '신규' 
        WHEN b.rev_cnt > 3 AND b.rev_cnt > 0 THEN '5회미만이용'
        WHEN b.rev_cnt >= 3 AND b.rev_cnt < 10 THEN '10회미만이용'
        WHEN b.rev_cnt >= 10 THEN '10회이상이용' END as rev_type, ## 이용횟수

  CASE WHEN r.way = 'd2d_round' THEN "부름"
       WHEN r.way = 'round' THEN '왕복' ELSE r.way END as riding_type, ## 부름/왕복
  
  date(r.end_at, 'Asia/Seoul') as edate, 
  r.car_id, c.car_num, c.car_name, cl.car_model,
  -- CASE WHEN r.zone_id != r.end_zone_id THEN '대차' ELSE '일반' END as r_type, ## 대차 받은 이용인지 아닌지
  datetime_diff(end_at, start_at, hour) as dur,
  CASE WHEN datetime_diff(end_at, start_at, hour) >= 10 THEN '장시간'
       WHEN datetime_diff(end_at, start_at, hour) < 10 THEN '단시간'
       WHEN datetime_diff(end_at, start_at, hour) < 5 THEN '초단시간' END as r_type4, ## 장/단시간


  CASE WHEN distance >= 90 THEN '장거리'
       WHEN distance < 90 THEN '단거리' END as r_type2, ## 이용거리
  distance,
  
  CASE WHEN substring(ssn, 8, 1) IN ('1', '3', '5', '7') THEN 'Male'
       WHEN substring(ssn, 8, 1) IN ('2', '4', '6', '8') THEN 'Female' END as sex, ## 성별 5 1900년대생 외국인 남자, 6/여자, 7 2000년대생 외국인 남자, 8 여자


  CASE WHEN datetime_diff(r.start_at, r.created_at, DAY) = 0 THEN 'r_dday' 
       WHEN datetime_diff(r.start_at, r.created_at, DAY) <= 3 THEN 'r_3day'
       WHEN datetime_diff(r.start_at, r.created_at, DAY) <= 7 THEN 'r_7dayU'
       WHEN datetime_diff(r.start_at, r.created_at, DAY) >= 7 THEN 'r_7dayO' END as r_type3, ## 예약과 예약시작일 차이

  ## 실적
  utime,
  pf_type, 
  accumulate_used_count, 
  acc_cnt,
  leadtime, 
  age_group,
  dist,
  coupon_id, coupon_policy_name,
  lesion_cnt,
  revenue,
  contribution_margin,
  __rev_rent_discount/__rent_refund as dc

FROM `tianjin_replica.reservation_info` r LEFT JOIN `tianjin_replica.member_info` m ON r.member_id = m.id
                                          LEFT JOIN `tianjin_replica.carzone_info` z ON r.zone_id= z.id
                                          LEFT JOIN `tianjin_replica.car_info` c ON r.car_id = c.id
                                          LEFT JOIN `tianjin_replica.car_class` cl ON c.class_id = cl.id
                                          LEFT JOIN base b ON r.member_id = b.member_id
                                          LEFT JOIN base4 b4 ON r.member_id = b4.member_id
                                          LEFT JOIN `soda_store.reservation_v2` sr ON r.id = sr.reservation_id
WHERE date(r.end_at, 'Asia/Seoul') BETWEEN current_date('Asia/Seoul') -31 AND current_date('Asia/Seoul')-1
                                  AND z.region1 IN ('제주특별자치도')
                                  AND r.state IN (3) AND r.member_imaginary IN (0, 9)
                                  AND r.zone_id IN (8539, 8548, 11884, 12762, 4504, 8744, 15322, 17378, 10490, 12812)
)

SELECT
  part, zone_id, zone_name,

  count(member_id) member_cnt,

  -- r.member_id,
  ## 신규
  count(CASE WHEN rev_type = '신규' THEN member_id END) as user_new,
  count(CASE WHEN rev_type = '5회미만이용' THEN member_id END) as user_5U,
  count(CASE WHEN rev_type = '10회미만이용' THEN member_id END) as user_10U,
  count(CASE WHEN rev_type = '10회이상이용' THEN member_id END) as user_10O,

  ## 시간
  count(CASE WHEN r_type4 = '장시간' THEN member_id END) as user_longtime,
  count(CASE WHEN r_type4 = '단시간' THEN member_id END) as user_shorttime,
  count(CASE WHEN r_type4 = '초단시간' THEN member_id END) as user_sstime,

  ## 거리
  count(CASE WHEN r_type2 = '장거리' THEN member_id END) as user_longrange,
  count(CASE WHEN r_type2 = '단거리' THEN member_id END) as user_shortrange,

  ## 사전예약률
  count(CASE WHEN r_type3 = 'r_7dayO' THEN member_id END) as user_7dayO,
  count(CASE WHEN r_type3 = 'r_7dayU' THEN member_id END) as user_7dayU,
  count(CASE WHEN r_type3 = 'r_3day' THEN member_id END) as user_3day,
  count(CASE WHEN r_type3 = 'r_dday' THEN member_id END) as user_day,

  ## 누적이용
  count(CASE WHEN accumulate_used_count < 5 THEN member_id END) as user_count5,
  count(CASE WHEN accumulate_used_count < 10 AND accumulate_used_count >= 5 THEN member_id END) as user_count10U,
  count(CASE WHEN accumulate_used_count >= 10 THEN member_id END) as user_count10O,

  ## 사고건수
  count(CASE WHEN acc_cnt = 0 THEN member_id END) as user_acc0,
  count(CASE WHEN acc_cnt <= 3 AND acc_cnt > 0 THEN member_id END) as user_acc3,
  count(CASE WHEN acc_cnt <= 10 AND acc_cnt > 3 THEN member_id END) as user_acc10,
  count(CASE WHEN acc_cnt > 10 THEN member_id END) as user_acc10O,

  ## 연령
  count(CASE WHEN age_type = '20s' THEN member_id END) as user_20,
  count(CASE WHEN age_type = '30s' THEN member_id END) as user_30,


FROM base_calc
GROUP BY part, zone_id, zone_name