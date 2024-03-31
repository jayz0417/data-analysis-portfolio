-- 2주 연속 손익부진 차량 분석용 쿼리

WITH base AS (
      SELECT year, month,
            week,
            case when zone_id in (105,9890) then 'air' else 'common' end as part,
            -- zone_id, zone_name,
            car_id, car_num,
            sum(standard_profit) as profit,
            CASE WHEN sum(standard_profit) < 0 THEN "minus_profit" ELSE "plus_profit" END as profit_type

      FROM `socar_biz.profit_biz_car_weekly_v2`
      WHERE region1 in ("제주특별자치도")
      AND year = 2023 AND month BETWEEN 1 AND 6
      AND zone_id not in (122,2184,11480,12072,12097,10736,10738,11947,13787,13858)
      and sharing_type in ('socar','zplus')
      GROUP BY year, month, week, part, car_id, car_num
),

base_raw AS (
      SELECT
            year, month, week,
            count(distinct CASE WHEN profit < 0 AND part = 'common' THEN car_id END) as profit_minus,
            count(distinct CASE WHEN profit >= 0 AND profit < 100000 AND part = 'common' THEN car_id END) as profit_over_0,
            count(distinct CASE WHEN profit >= 100000 AND profit < 200000 AND part = 'common' THEN car_id END) as profit_over_10,
            count(distinct CASE WHEN profit >= 200000 AND profit < 300000 AND part = 'common' THEN car_id END) as profit_over_20,
            count(distinct CASE WHEN profit >= 300000 AND profit < 400000 AND part = 'common' THEN car_id END) as profit_over_30,
            count(distinct CASE WHEN profit >= 400000 AND part = 'common' THEN car_id END) as profit_over_40,

            count(distinct CASE WHEN profit < 0 AND part = 'air' THEN car_id END) as profit_minus_air,
            count(distinct CASE WHEN profit >= 0 AND profit < 100000 AND part = 'air' THEN car_id END) as profit_over_0_air,
            count(distinct CASE WHEN profit >= 100000 AND profit < 200000 AND part = 'air' THEN car_id END) as profit_over_10_air,
            count(distinct CASE WHEN profit >= 200000 AND profit < 300000 AND part = 'air' THEN car_id END) as profit_over_20_air,
            count(distinct CASE WHEN profit >= 300000 AND profit < 400000 AND part = 'air' THEN car_id END) as profit_over_30_air,
            count(distinct CASE WHEN profit >= 400000 AND part = 'air' THEN car_id END) as profit_over_40_air

      FROM base
      GROUP BY year, month, week
      ORDER BY year, month, week
),


base2 AS (
      SELECT 
            *,
            lag(profit_type) OVER(partition by car_id order by week) as prev
      FROM base
      ORDER BY year, month, car_id
)

SELECT
      year, month, week,
      sum(CASE WHEN part = 'air' THEN continuity_minus_cnt END) as air_continuity_minus_cnt,
      sum(CASE WHEN part = 'common' THEN continuity_minus_cnt END) as common_continuity_minus_cnt
FROM
      (SELECT
            year,month, week, part, 
            count(CASE WHEN profit_type = 'minus_profit' AND prev = 'minus_profit' THEN car_id END) as continuity_minus_cnt
      FROM base2
      GROUP BY year, month, week, part
      ORDER BY year, month, week, part)
GROUP BY year, month, week
ORDER BY year, month, week