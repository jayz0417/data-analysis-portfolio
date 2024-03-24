-- 유저타입 (라이트/헤비), 이용타입 (단거리/장거리) / (단시간/장시간) 
-- 유저 정보 (user_id 매칭 ), 이용 정보(riding_id, user_id 매칭) count(riding_id), sum(used_min) / count(riding_id), sum(distance) / count(riding_id)

WITH user_info AS (
    SELECT 
        user.id as user_id, user.joined_date, user.last_login_date, 
        CASE WHEN gender = 1 THEN '남성'
             WHEN gender = 2 THEN '여성'
             WHEN gender = 0 THEN '미인증' END as gender,  
        age_range,

        riding.id as riding_id, riding.area, riding.start_date as riding_date, 

        CASE WHEN extract(hour FROM riding.start_time) BETWEEN 6 and 11 THEN '오전'
             WHEN extract(hour FROM riding.start_time) BETWEEN 12 and 17 THEN '오후'
             WHEN extract(hour FROM riding.start_time) BETWEEN 18 and 24 THEN '전반야'
             WHEN extract(hour FROM riding.start_time) BETWEEN 0 AND 5 THEN '후반야' END as time_range, -- 이용시작 시간대 범주형 구분

        CASE WHEN user.is_staff = true THEN '직원' ELSE '고객' END as is_staff, -- 임직원 사용여부

        riding.used_min, riding.distance,
        CASE WHEN JSON_EXTRACT_SCALAR(riding.extra, '$.subscription_purchase_id') is not null or JSON_EXTRACT_SCALAR(riding.extra, '$.riding_pass_id') is not null then 'pass_user' ELSE 'non_pass' END as pass_user, -- 구독 상품 사용 여부 구분
        billing.amount, billing.refund, billing.income -- 결제 정보
    FROM elecle_slave.tf_user user LEFT JOIN elecle_slave.tf_riding riding ON user.id = riding.user_id LEFT JOIN elecle_slave.tf_billing billing ON riding.billing_id = billing.id
    WHERE riding.start_date >= '2021-01-01'AND riding.organization_id is null
), -- 유저 정보

user_type_raw AS (
    SELECT
        user_id, joined_date, last_login_date, gender, age_range, area,
        DATE(DATE_TRUNC(riding_date, month)) AS month, 
        is_staff, pass_user, 
        count(riding_id) as month_riding, sum(used_min) as month_used_min, sum(distance) as month_distance, 
        sum(amount) as month_amount, sum(refund) as month_refund, sum(income) as month_income
    FROM user_info
    GROUP BY user_id, joined_date, last_login_date, gender, age_range, area, month, is_staff, pass_user
    ORDER BY user_id, month
), 유저 타입별 매출 지표

user_type AS (
    SELECT
        user_id, month, 
        CASE WHEN count(user_id) >= 8 THEN 'Heavy' ELSE 'Light' END as ut
    FROM user_type_raw 
    GROUP BY user_id, month
) -- 헤비 유저 여부

-- 유저 id, 가입일, 최근이용일, 성별, 연령, 지역, 이용시간대, 
SELECT 
    user_id, joined_date, last_login_date, gender, age_range, r.title, time_range, pass_user, is_staff, riding_date,
    count(riding_id) as riding_cnt, count(time_range) as time_cnt, count(pass_user) as pass_cnt,
    sum(used_min) /count(riding_id) as used_min_riding, sum(distance) / count(riding_id) as distance_riding,
    sum(amount) as mount, sum(refund) as refund, sum(income) as income,
    sum(income) / count(riding_id) as income_riding
FROM user_info u LEFT JOIN management.region r ON u.area = r.area_cd
GROUP BY user_id, joined_date, last_login_date, gender, age_range, r.title, time_range, pass_user, is_staff, riding_date
ORDER BY user_id, riding_date, time_range