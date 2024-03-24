-- 상품 매출을 분석하기 위한 쿼리
-- base raw 값 
-- purchase 상품 구매내역 -> purchased_item_stack 구매한 상품으로 이용한 riding 내역
-- purchase -> product 구매한 상품
-- purchased_item_stack -> tf_riding 라이딩 기록
-- tf_riding -> tf_billing 라이딩 매출 기록
-- tf_riding -> region 이용 지역 값
-- base1 -> 상품매출 (purchase 테이블의 billing_id)
-- base2 -> 라이딩매출 (purchased_item_stacked의 riding_id의 billing_id)

WITH base1 AS (
    SELECT 
        p.id as purchase_id, 
        p.product_id, po.name,
        pis.id as riding_id,
        tb.charge, tb.amount, tb.refund, tb.income, tb.discount_agg, tb.discount_subscription
    FROM elecle_slave.purchase p LEFT JOIN elecle_slave.purchased_item_stack pis ON p.id = pis.purchase_id
                                 LEFT JOIN elecle_slave.product po ON p.product_id = po.id
                                 LEFT JOIN elecle_slave.tf_billing tb ON p.billing_id = tb.id
   -- 이용중인 상품 제외 , 21년1월1일 이후 등록된 상품과 구매만 필터링
    WHERE p.status < 20 AND po.created_at >= '2021-01-01' AND p.created_at >='2021-01-01'
), -- 상품 매출 정보

base2 AS (
    SELECT 
        p.id as purchase_id, 
        p.product_id, po.name,
        pis.id as riding_id,
        tr.used_min, 
        tb.charge, tb.amount, tb.refund, tb.income, tb.discount_agg, tb.discount_subscription
    FROM elecle_slave.purchase p LEFT JOIN elecle_slave.purchased_item_stack pis ON p.id = pis.purchase_id
                                 LEFT JOIN elecle_slave.product po ON p.product_id = po.id
                                 LEFT JOIN elecle_slave.tf_riding tr ON pis.id = tr.id
                                 LEFT JOIN elecle_slave.tf_billing tb ON tr.billing_id = tb.id
                                 LEFT JOIN management.region r ON tr.area = r.area_cd
    -- 이용중인 상품 제외, 상품 등록과 구매가 21년1월1일 이후로 필터링
    WHERE p.status < 20 AND po.created_at >= '2021-01-01' AND p.created_at >='2021-01-01'
), 

base_total AS (
    SELECT
         b1.purchase_id, b1.product_id, b1.name as po_name,
         b2.riding_id,
         b2.used_min, b2.charge, b2.amount, b2.refund, b2.income, b2.discount_agg, b2.discount_subscription,
         b1.income as po_income
    FROM base1 b1 LEFT JOIN base2 b2 ON b1.purchase_id = b2.purchase_id
),

total_calc1 AS (
    SELECT 
        product_id, po_name,
        count(distinct purchase_id) as purchase_cnt,
        count(riding_id) as riding_cnt,
        sum(used_min) as used_min,
        sum(charge) as charge, sum(amount) as amount, sum(refund) as refund, sum(income) as riding_income,
        sum(discount_agg) as discount_agg, sum(discount_subscription) as discount_subscription,
        sum(po_income) as po_income
    FROM base_total
    GROUP BY product_id, po_name
)

SELECT 
    product_id, po_name, purchase_cnt, riding_cnt, 
    round(used_min, 1) used_min, charge, amount, refund, riding_income,
    discount_agg, discount_subscription, po_income
FROM total_calc1
ORDER BY product_id 