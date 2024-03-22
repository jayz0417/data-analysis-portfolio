-- 2021.08
-- 일레클이 운영을 시작한 이후부터 판매된 각 Product(일반 대여, 구독 상품, 쿠폰 등)에서 발생한 매출을 재무적으로 정산하여 통합 관리하기  위한 쿼리


-- 날짜 생성을 위한 날짜 변수 선언
-- first_date 시작일
-- last_date 종료일 -> 유효기간을 고려하여 오늘 날짜이후 180일까지를 생성
DECLARE first_date date default '2020-03-26';
DECLARE last_date date default current_date('Asia/Seoul') + 180;

-- 구매 테이블에서 기본 정보 가져옮
-- date_diff -> 날짜간의 차이만큼 매출값을 계산하고자 사용 = 일할 매출
-- +1의 이유는 뒤에서 from_date, to_date를 BETWEEN(이상/이하) 조건으로 위에서 선언한 date를 사용하기 때문
-- from_date가 null인 경우, purchased_date로 대체하여 계산 
-- to_date가 null인 경우, purcased_date + days(유효기간)으로 대체하여 계산
WITH purchase_raw AS (
    SELECT 
      purchase_id, product_id, user_id, billing_id, purchased_date, from_date, to_date,
      amount / (date_diff(to_date, from_date, DAY)+1) as unit_amount,
      refund / (date_diff(to_date, from_date, DAY)+1) as unit_refund,
      income / (date_diff(to_date, from_date, DAY)+1) as unit_income,
    FROM
    (SELECT 
      purchase_id, product_id, user_id, billing_id,
      purchased_date,
      CASE WHEN from_date is null THEN purchased_date ELSE from_date END as from_date,
      CASE WHEN to_date is null THEN purchased_date + days ELSE to_date END as to_date,
      amount, refund, income
    FROM elecle_slave.tf_purchase_table pt LEFT JOIN elecle_slave.product p ON pt.product_id = p.id) a
),

-- 첫 이용 정보 및 이용건수 생성
-- 구매 id로 이용된 riding_id를 order_by 조건으로 rank를 생성하여 1, 2순위(첫번째 두번째) 지역 정보를 가져옮
first_riding1 AS (
    SELECT 
      purchase_id, 
      riding_id, 
      rank
    FROM (
          SELECT 
            purchase_id, riding_id, 
            row_number() over (partition by purchase_id order by riding_id) as rank
          FROM elecle_slave.purchased_item_stack) a
    WHERE rank in (1, 2)
),

-- 첫번쨰 지역 정보를 city로, 두번째 지역 정보를 next_city로 하나의 행으로 만듦
riding_area AS (
    SELECT 
      purchase_id, rank, city,
      lead(city, 1) over (partition by purchase_id order by rank) as next_city
    FROM
    (
      SELECT 
        fr.purchase_id, 
        fr.riding_id, 
        fr.rank,
        r.title as city,
      FROM first_riding1 fr LEFT JOIN elecle_slave.tf_riding tr ON fr.riding_id = tr.id
                            LEFT JOIN management.region r ON tr.h3_start_area_name = r.area_name) a
),

riding_area2 AS (
    SELECT purchase_id, city, next_city
    FROM riding_area
    WHERE rank = 1
),

-- 구매 id별 이용정보, 일할 매출액 시트
purchase_area AS (
    SELECT 
      pr.purchase_id, 
      product_id, 
      user_id, 
      billing_id, 
      purchased_date, 
      from_date, to_date,
      ra2.city,
      unit_amount, unit_refund, unit_income
    FROM purchase_raw pr LEFT JOIN riding_area2 ra2 ON pr.purchase_id = ra2.purchase_id
),

-- 날짜 테이블 생성
D AS (
    SELECT date FROM unnest(generate_date_array(first_date, last_date)) as date 
)

-- 지역 정보 없을 경우 기타 처리
-- 각 매출지표 값이 null일 경우 0원 처리
-- 구매 테이블이 from_date AND to_date 사이를 조건으로 날짜를 생성하여 billing 정보 insert
SELECT 
  date, 
  date_trunc(date, week(monday)) as week, 
  date_trunc(date, month) as month, 
  CASE WHEN city is null THEN '기타' ELSE city END as city, 
  ifnull(unit_amount, 0) as unit_amount, 
  ifnull(unit_refund, 0) as unit_refund, 
  ifnull(unit_income, 0) as unit_income
FROM
  (
    SELECT 
      D.date, city, 
      sum(unit_amount) as unit_amount, 
      sum(unit_refund) as unit_refund, 
      sum(unit_income) as unit_income
  FROM D, purchase_area pa 
  WHERE D.date BETWEEN pa.from_date AND pa.to_date
  GROUP BY date, city
  )
ORDER BY date desc, city