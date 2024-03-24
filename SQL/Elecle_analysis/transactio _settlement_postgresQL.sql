-- 날짜 생성
WITH D AS (
SELECT a.date + b.idx as date
FROM (SELECT '2021-01-01'::date as date) a CROSS JOIN (SELECT generate_series(0, 364) as idx) b
),

-- purchase 정리
table1 AS (
SELECT id as purchase_id, product_id , lower(term) AT TIME ZONE 'kst' as from_date, upper(term) AT TIME ZONE 'kst' as to_date, status, user_id, date(activated_at AT TIME ZONE 'kst') as activate_date
FROM public.purchase),

-- 날짜 타입 정리
table_date AS (
SELECT table1.purchase_id, table1.product_id, to_char(from_date, 'YYYY-MM-DD') as from_date, to_char(to_date + '1 day', 'YYYY-MM-DD') as to_date, status, user_id, activate_date, 
a.name, a.days, a.price
FROM table1 LEFT JOIN public.product a ON table1.product_id = a.id
),

table2 AS (
SELECT purchase_id, product_id, to_date(from_date, 'yyyy-mm-dd') as from_Date, to_date(to_date, 'yyyy-mm-dd') as to_date, status, user_id, activate_date, 
name, days, price
FROM table_date
),

-- riding_id 추가하기 위한 join
table3 AS (
SELECT table2.*, a.riding_id
FROM table2 LEFT JOIN public.purchased_item_stack a ON table2.purchase_id = a.purchase_id
),

-- billing 지표 추가
table4 AS (
SELECT a.*, c.amount, c.income - c.amount as refund, c.income
FROM table3 a LEFT JOIN public.riding b ON a.riding_id = b.id LEFT JOIN public.billing c ON b.billing_id = c.id
),

-- 정기권을 사용한 riding_의 매출(상품 판매금액 x, 대여요금 o)
-- days 상품의 유효기간
-- 상품가격 / 유효기간 = 상품의 일할 매출액
-- amount, refund, income = 정기권 상품의 riding 매출
table5 AS (
SELECT purchase_id, product_id, name, price, days, from_date, to_date, status, user_id, riding_id,
sum(amount) as amount, sum(refund) as refund, sum(income) as income,
price / days as unit_product_income
FROM table4
GROUP BY purchase_id, product_id, name, price, days, from_date, to_date, status, user_id, riding_id
),

-- region
table6 AS (
SELECT a.*, c.name as region
FROM table5 a LEFT JOIN public.riding b ON a.riding_id = b.id LEFT JOIN public.geo_region c ON b.region = c.code
),

-- 위에서 만들어 놓은 날짜 테이블 D를 from_to date안에 있는 조건으로 맞추고,
-- 날짜별로 재계산(sum)
daily AS (
SELECT D.date, region, 
count(product_id) as product_cnt, count(purchase_id) as purchase_cnt,
coalesce(sum(amount), 0, sum(amount)) as amount,
coalesce(sum(refund), 0, sum(refund)) as refund,
coalesce(sum(income), 0, sum(income)) as income,
coalesce(sum(unit_product_income), 0, sum(unit_product_income)) as unit_product_income
FROM table6, D
WHERE D.date BETWEEN table6.from_date AND table6.to_date
GROUP BY date, region
ORDER BY date, region
)

SELECT * FROM daily
-- 상품매출분석 쿼리 postgreSQL