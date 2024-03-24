-- 가맹점 정산을 위한 쿼리

#standardSQL

WITH D AS (
  SELECT * FROM date.ops_date -- 운영팀의 분석용 쿼리에 사용하기 위해 만들어놓은 날짜 테이블
),

riding_base AS (
    SELECT
        end_date as date,
        CASE WHEN r.region_name is null THEN '기타' ELSE r.region_name END as city,
        CASE WHEN r.area_name is null THEN '기타' ELSE r.area_name END as area,
        id as riding_id
    FROM elecle_slave.tf_riding tr LEFT JOIN management.region r ON tr.h3_end_area_name = r.area_name
    WHERE fee > 0 AND riding_type in (0, 2)
), -- riding의 이용종료 시점에 따른 지역별 정보

rb_calc AS (
    SELECT 
        date,
        city as name,
        area,
        count(riding_id) as riding_cnt
    FROM riding_base
    GROUP BY date, name, area
), -- 지역별 이용된 건수

riding AS (
    SELECT D.date, name, area, riding_cnt
    FROM D, rb_calc
    WHERE D.date = rb_calc.date
), -- 날짜별로 종료 기준의 riding 정보 결합

income_base AS (
  SELECT
    date, name, area, sum(income) as income
  FROM
    (SELECT
      br.end_date as date, b.payment, br.id as riding_id, r.region_name as name, r.area_name as area,
      b.income, riding_type
    FROM elecle_slave.tf_riding br LEFT JOIN elecle_slave.tf_billing b ON br.billing_id = b.id
                                       LEFT JOIN management.region r ON br.area = r.area_cd
    WHERE b.status >= 2 AND br.fee > 0) a
  WHERE (riding_type = 0 OR riding_type = 2)
  GROUP BY date, name, area
), -- 기본 매출 정보

non_income AS (
  SELECT
    date, name, area, sum(income) as income
  FROM
    (SELECT
      br.end_date as date, b.payment, br.id as riding_id, r.region_name as name, r.area_name as area,
      b.income, riding_type
    FROM elecle_slave.tf_riding br LEFT JOIN elecle_slave.tf_billing b ON br.billing_id = b.id
                                       LEFT JOIN management.region r ON br.area = r.area_cd
    WHERE b.status < 2 AND br.fee > 0) a
  WHERE (riding_type = 0 OR riding_type = 2)
  GROUP BY date, name, area
), -- 환불정보

product_income AS (
  SELECT D.date, income.name, income.area, income.income
  FROM D, income_base income
  WHERE income.date = D.date
  ORDER BY date
), -- 상품별 판매정보

product_nincome AS (
  SELECT D.date, non_income.name, non_income.area, non_income.income as n_income
  FROM D, non_income
  WHERE non_income.date = D.date
  ORDER BY date
), -- 상품별 환불정보

-- 상품 매출을 구매후 첫 이용지역에 적용
-- 결제가 완료되고 환불되지 않은 purchase (!= 0, 13)
-- 구매 테이블 데이터 정리
purchase_raw AS (
    SELECT 
        distinct purchase_date, purchase_id, product_id, a.billing_id, from_date, to_date,
        a.amount / (date_diff(to_date, from_date, day) + 1) as unit_amount,
        a.income / (date_diff(to_date, from_date, day) + 1) as unit_income,
        sum(CASE WHEN bs.type >= 1 THEN bs.amount ELSE 0 END) over (partition by purchase_date, purchase_id, product_id, a.billing_id, from_date, to_date) / (date_diff(to_date, from_date, day) + 1) as unit_refund
    FROM
        (SELECT extract(date FROM p.created_at AT TIME ZONE 'Asia/Seoul') as purchase_date,
        p.id as purchase_id, p.product_id, p.billing_id,
        p.status,
        -- CASE 문 내용
        -- purchase의 활성화가 안되어 있다면 구매된 시점을, 활성화가 되었다면 활성화 시점을 from_date로 지정
    --     → purchase.deactivated_at이 Null 이라면 purchase.activated_at + product.days
    --     → purchase.deactivated_at이 Null 이면서 purchase.activated_at도 Null 이라면 purchase.created_at + product.days로 처리
        CASE WHEN p.activated_at is null THEN extract(date FROM p.created_at AT TIME ZONE 'Asia/Seoul') ELSE extract(date FROM activated_at AT TIME ZONE 'Asia/Seoul') END as from_date,
        CASE WHEN p.activated_at is null AND p.deactivated_at is null THEN extract(date FROM p.created_at AT TIME ZONE 'Asia/Seoul') + po.days 
            WHEN p.deactivated_at is null THEN extract(date FROM p.activated_at AT TIME ZONE 'Asia/Seoul') + po.days 
            ELSE extract(date FROM p.deactivated_at AT TIME ZONE 'Asia/Seoul') END as to_date,
        b.amount, b.income, days
        FROM elecle_slave.purchase p LEFT JOIN elecle_slave.product po ON p.product_id = po.id
                                        LEFT JOIN elecle_slave.tf_billing b ON p.billing_id = b.id
        WHERE p.status >= 5) a 
    LEFT JOIN elecle_slave.billing_stack bs ON a.billing_id = bs.billing_id
),

first_riding AS (
SELECT purchase_id, riding_id, rank
FROM (SELECT purchase_id, riding_id,
      row_number() over (partition by purchase_id order by riding_id) as rank
      FROM elecle_slave.purchased_item_stack) a
WHERE rank in (1, 2)
), -- 첫 이용지역 구분용 

riding_area AS (
SELECT 
    purchase_id, rank, 
    city,
    lead(city, 1) over (partition by purchase_id order by rank) as next_city,
    area,
    lead(area, 1) over (partition by purchase_id order by rank) as next_area
FROM
    (SELECT fr.purchase_id, fr.riding_id, fr.rank, rg.region_name as city, rg.area_name as area
    FROM first_riding fr LEFT JOIN mainstream.riding r ON fr.riding_id = r.id
LEFT JOIN management.region rg ON r.area = rg.area_cd) a
), 

riding_area2 AS (
    SELECT purchase_id, city, next_city, area, next_area
    FROM riding_area
    WHERE rank = 1
),

purchase_area AS (
    SELECT 
        pr.purchase_id, product_id, billing_id, purchase_date, from_date, to_date, ra2.city, ra2.area,
        unit_amount, unit_refund, unit_income
    FROM purchase_raw pr LEFT JOIN riding_area2 ra2 ON pr.purchase_id = ra2.purchase_id
),

purchase_d AS (
SELECT 
    date, date_trunc(date, week(monday)) as week, date_trunc(date, month) as month,
    CASE WHEN city is null THEN '기타' ELSE city END as city,
    CASE WHEN area is null THEN '기타' ELSE area END as area,
    coalesce(unit_amount, 0) as unit_amount, coalesce(unit_refund, 0) as unit_refund, coalesce(unit_income, 0) as unit_income
FROM
    (SELECT D.date, city, area, sum(unit_amount) as unit_amount, sum(unit_refund) as unit_refund, sum(unit_income) as unit_income
    FROM purchase_area pa, D
    WHERE D.date BETWEEN pa.from_date AND pa.to_date
    GROUP BY date, city, area) a
ORDER BY date desc, city, area
),

purchase_product AS (
    SELECT 
        pi.date, pi.name, pi.area,
        CASE WHEN pi.income is null THEN 0 ELSE pi.income END as income,
        CASE WHEN npi.n_income is null THEN 0 ELSE npi.n_income END as n_income,
        CASE WHEN pd.unit_amount is null THEN 0 ELSE pd.unit_amount END as pd_unit_amount,
        CASE WHEN pd.unit_refund is null THEN 0 ELSE pd.unit_refund END as pd_unit_refund,
        CASE WHEN pd.unit_income is null THEN 0 ELSE pd.unit_income END as pd_unit_income
    FROM product_income pi LEFT JOIN product_nincome npi ON pi.date = npi.date AND pi.area = npi.area
                           LEFT JOIN purchase_d pd ON pi.date = pd.date AND pi.area = pd.area
),

sales AS (
    SELECT 
        date, name, area, income, n_income, pd_unit_income as unit_income,
        pd_unit_income + income + n_income as total_income
    FROM purchase_product
),

sales2 AS (
    SELECT 
        date, name, area,
        income, n_income, unit_income,
        income + unit_income as billing_income,
        total_income
    FROM sales
),

riding_sales AS (
    SELECT 
        s2.date, s2.name, s2.area,
        riding_cnt, income, n_income, unit_income, billing_income, total_income
    FROM sales2 s2 LEFT JOIN riding r ON s2.date = r.date AND s2.area = r.area
)

SELECT 
    extract(year FROM date) as year, extract(month FROM date) as month, date,
    name, area,
    riding_cnt, income, n_income, unit_income, billing_income, total_income
FROM riding_sales
WHERE area = '창원권역' AND date < "2022-04-01"
ORDER BY date desc