-- 23y 23M 차량 재배치 실적 분석용 쿼리

CREATE TEMP FUNCTION set_region(zone_id any TYPE) AS (
  CASE WHEN zone_id IN (737, 12689, 17046, 110, 2819, 2820, 8743, 8744, 10978, 11456, 13744, 13881, 14264, 15322, 16619, 16620, 17020, 17212, 17270, 17378, 10652, 2574, 5828, 8113, 14217, 17053, 17054, 17184, 17145, 12236, 12362, 12583, 14697, 12929, 12930, 17996, 18202, 18203, 10652, 12689, 12929, 12930, 18623, 18857,18867, 3558) THEN '공항주변'
       WHEN zone_id IN (10654, 2230, 16618, 17154, 14451, 12703, 18269, 12703, 10654, 18422, 18423, 18728, 18730, 1967) THEN '구서귀포'
       WHEN zone_id IN (651, 737, 2629, 2341, 2629, 4874, 12661, 11453, 10490, 14430, 14518, 14520, 15304, 16621, 16898, 17465, 114, 14167, 17208, 651, 18204, 18205, 4874, 11453, 2341, 18467, 18426, 4502, 6338) THEN '구제주'
       WHEN zone_id IN (879, 14420, 7906, 12762, 13657, 14943, 17196, 17463, 13657, 14943, 879, 18424, 7941) THEN '신서귀포'
       WHEN zone_id IN (3967, 3969, 10892, 11165, 12538, 12959, 12858, 12857, 13400, 7288, 11587, 13969, 10391, 12521, 12812, 14757, 16265, 4504, 8539, 8548, 8741, 11884, 13581, 13597, 14361, 14554, 15397, 16363, 16365, 16997, 17185, 13818, 17836, 18151, 17777, 18206, 3969, 7288, 12538, 13597, 13818, 13969, 11587, 12959, 14757, 10892, 3967, 1564, 16363, 16365, 15397, 18462) THEN '외곽'
       WHEN zone_id IN (17209) THEN '공항앞'
       WHEN zone_id IN (5894, 12636, 16126, 246, 13606, 16321, 18261, 5894) THEN '중문'
       WHEN zone_id IN (18471, 18472, 18473) THEN '실증사업'
       WHEN zone_id IN (105, 9890) THEN '제주공항' ELSE cast(zone_id as string) END
); ## 마지막 업데이트 2023.12.06 신규존 추가

WITH base_geo AS (
  SELECT
    zid, zname,
    region1, region2, region3,
    lng, lat,
    ST_GEOGPOINT(lng, lat) as geo_st, 


  FROM
  (
    SELECT
      z.id as zid,
      z.zone_name as zname,
      z.region1, z.region2, z.region3,
      z.lng, z.lat
    FROM `tianjin_replica.carzone_info` z 
    WHERE z.region1 = '제주특별자치도' AND state = 1
  )

),

geo2 AS (
  SELECT
    zid, zname, 
    region1, region2, region3, 
    lng, lat,
    geo_st,
    -- ST_CLUSTERDBSCAN(geo_st, 5000, 3) OVER() as geo_group
  FROM base_geo
),

base_p AS (
  SELECT  
    extract(year from date) as year,
    extract(month from date) as m,
    extract(isoweek from date) as w,
    date,

    CASE WHEN p.zone_id IN (105, 990) THEN 'air'
         WHEN p.zone_id IN (17209) THEN 'air_infront'
         WHEN p.zone_id IN (18471, 18472, 18473) THEN 'test' ELSE 'common' END as part,
    
    set_region(p.zone_id) as part2,

    p.zone_id as zid,
    p.zone_name as zname, 
    
    count(car_id) as cnt,
    sum(opr_day) as opr_day,
    sum(nuse) as use,
    sum(nuse_passport+nuse_socarpass) as use_p,
    sum(utime) as dur,
    sum(revenue) as revenue,
    sum(_rev_rent) as rent,
    sum(profit) as profit,
    sum(cost_variable) as vcost,
    sum(cost_fixed) as fcost,
    sum(nuse_round) as use_round,
    sum(nuse_oneway) as use_oneway,
    sum(nuse_d2d_round) as use_d2d_round,
    sum(nuse_d2d_oneway) as use_d2d_oneway,
    sum(nuse_z2d_oneway) as use_z_oneway

  FROM    `socar_biz_profit.profit_socar_car_daily` p 
  left join `tianjin_replica.carzone_info` z on p.zone_id=z.id
  WHERE TRUE AND car_sharing_type IN ('socar', 'zplus')
             AND date BETWEEN '2019-01-01' AND current_date('Asia/Seoul')
             AND p.region1 = '제주특별자치도'
             AND zone_id not in(122,2184,12072,12073,10736,10738,11947,11480,13228,13787,13858,14494,14528,14541,14542)
  GROUP BY year, m, w, date, part, part2, zid, zname
),

p_28 AS (
  SELECT
    part, part2, zid, zname, 
    safe_divide(sum(dur), (sum(opr_day)*24)) as op_rate28,
    safe_divide(sum(dur), sum(use)) as dur_use28,
    safe_divide(sum(revenue), avg(opr_day)) as revenue_car28,
    safe_divide(sum(profit), avg(opr_day)) as profit_car28,
    avg(cnt) as cnt,
    sum(opr_day) as opr_day,
    sum(use) as use,
    sum(use_p) as use_p,
    sum(dur) as dur,
    sum(revenue) as revenue,
    sum(rent) as rent,
    sum(profit) as profit,
    sum(vcost) as vcost,
    sum(fcost) as fcost,
    sum(use_round) as use_round,
    sum(use_oneway) as use_oneway,
    sum(use_d2d_round) as use_d2d_round,
    sum(use_d2d_oneway) as use_d2d_oneway,
    sum(use_z_oneway) as use_z_oneway    
  FROM base_p
  WHERE date >= current_date('Asia/Seoul') -28
  GROUP BY part, part2, zid, zname
),

p_2023 AS (
  SELECT
    part, part2, zid, zname, 
    safe_divide(sum(dur), (sum(opr_day)*24)) as op_rate2023,
    safe_divide(sum(dur), sum(use)) as dur_use2023,
    safe_divide(sum(revenue), avg(opr_day)) as revenue_car2023,
    safe_divide(sum(profit), avg(opr_day)) as profit_car2023,
    avg(cnt) as cnt,
    sum(opr_day) as opr_day,
    sum(use) as use,
    sum(use_p) as use_p,
    sum(dur) as dur,
    sum(revenue) as revenue,
    sum(rent) as rent,
    sum(profit) as profit,
    sum(vcost) as vcost,
    sum(fcost) as fcost,
    sum(use_round) as use_round,
    sum(use_oneway) as use_oneway,
    sum(use_d2d_round) as use_d2d_round,
    sum(use_d2d_oneway) as use_d2d_oneway,
    sum(use_z_oneway) as use_z_oneway    
  FROM base_p
  WHERE date >= '2023-01-01'
  GROUP BY part, part2, zid, zname
),

p_2022 AS (
  SELECT
    part, part2, zid, zname, 
    safe_divide(sum(dur), (sum(opr_day)*24)) as op_rate2022,
    safe_divide(sum(dur), sum(use)) as dur_use2022,
    safe_divide(sum(revenue), avg(opr_day)) as revenue_car2022,
    safe_divide(sum(profit), avg(opr_day)) as profit_car2022,
    avg(cnt) as cnt,
    sum(opr_day) as opr_day,
    sum(use) as use,
    sum(use_p) as use_p,
    sum(dur) as dur,
    sum(revenue) as revenue,
    sum(rent) as rent,
    sum(profit) as profit,
    sum(vcost) as vcost,
    sum(fcost) as fcost,
    sum(use_round) as use_round,
    sum(use_oneway) as use_oneway,
    sum(use_d2d_round) as use_d2d_round,
    sum(use_d2d_oneway) as use_d2d_oneway,
    sum(use_z_oneway) as use_z_oneway    
  FROM base_p
  WHERE date >= '2022-01-01'
  GROUP BY part, part2, zid, zname
),

p_3year AS (
  SELECT
    part, part2, zid, zname, 
    safe_divide(sum(dur), (sum(opr_day)*24)) as op_rate3,
    safe_divide(sum(dur), sum(use)) as dur_use3,
    safe_divide(sum(revenue), avg(opr_day)) as revenue_car3,
    safe_divide(sum(profit), avg(opr_day)) as profit_car3,
    avg(cnt) as cnt,
    sum(opr_day) as opr_day,
    sum(use) as use,
    sum(use_p) as use_p,
    sum(dur) as dur,
    sum(revenue) as revenue,
    sum(rent) as rent,
    sum(profit) as profit,
    sum(vcost) as vcost,
    sum(fcost) as fcost,
    sum(use_round) as use_round,
    sum(use_oneway) as use_oneway,
    sum(use_d2d_round) as use_d2d_round,
    sum(use_d2d_oneway) as use_d2d_oneway,
    sum(use_z_oneway) as use_z_oneway    
  FROM base_p
  WHERE date BETWEEN '2020-01-01' AND '2022-12-31'
  GROUP BY part, part2, zid, zname
),

base_p_union AS (
  SELECT
    g.*,
    p28.op_rate28, p28.dur_use28, p28.revenue_car28, profit_car28, 
    p23.op_rate2023, p23.dur_use2023, p23.revenue_car2023, p23.profit_car2023,
    p22.op_rate2022, p22.dur_use2022, p22.revenue_car2022, p22.profit_car2022,
    p3.op_rate3, p3.dur_use3, p3.revenue_car3, p3.profit_car3,



  FROM base_geo g LEFT JOIN p_28 p28 ON g.zid = p28.zid
                  LEFT JOIN p_2023 p23 ON g.zid = p23.zid
                  LEFT JOIN p_2022 p22 ON g.zid = p22.zid
                  LEFT JOIN p_3year p3 ON g.zid = p3.zid
),

base_zClick AS (
	select
			sdate,
      zid,
			zname,
			count(distinct(mid)) as unique_click_cnt,
			count(distinct(r.id)) as rev_cnt,
			safe_divide(count(distinct(r.id)),count(distinct(mid))) as rev_Rate,
			extract(isoweek from sdate) as w

	from(
		select
			date(a.event_timestamp,"Asia/Seoul") as date, #존을클릭한날
      date(a.start_at, "Asia/Seoul") as sdate,#존클릭예약시작조회날
			a.member_id as mid,#존클릭예약자
			c.id as class_id, #존클릭조회차량클래스id
			date(a.start_at,"Asia/Seoul") as start_at,#예약시작일
			date(a.end_at,"Asia/Seoul") as end_at, #예약종료일
			a.zone_id as zid,        #존id
			z.zone_name as zname,
		from socar_server_2.get_car_classes a , tianjin_replica.carzone_info z, unnest(carClasses) c
		where true=true and a.zone_id = z.id
                    AND z.id NOT IN(13858, 17651, 17784)
                    and date(a.event_timestamp,"Asia/Seoul") < current_Date("Asia/Seoul")
                    and date(a.start_at,"Asia/Seoul") >= '2019-01-01'
                    and z.region1 = '제주특별자치도'
				-- 조회시점에 따라 위 날짜 조건을 조정해야함
		) click #존클릭자수테이블

	join tianjin_replica.member_info m on m.id = click.mid and m.imaginary in (0) #멤버정보(쏘친,쏘팸)
	left join tianjin_replica.reservation_info r on r.member_id = click.mid #예약정보테이블
                                                and r.zone_id = click.zid
                                                and date(r.start_at, "Asia/Seoul") = click.sdate #예약시작과존클릭시작을leftjoin
                                                and r.state in (1,2,3) #예약,운행,완료
                                                and r.way in ('round') #왕복예약

	group by sdate, zname, zid
	order by sdate, zname, zid
),

zclick AS (
  SELECT 
    zid, zname,
    sum(CASE WHEN sdate >= current_date('Asia/Seoul')-28 THEN unique_click_cnt END) as unique_click_cnt28,
    sum(CASE WHEN sdate BETWEEN '2023-01-01' AND '2023-12-31' THEN unique_click_cnt END) as unique_click_cnt2023,
    sum(CASE WHEN sdate BETWEEN '2022-01-01' AND '2022-12-31' THEN unique_click_cnt END) as unique_click_cnt2022,
    
    avg(CASE WHEN sdate >= current_date('Asia/Seoul')-28 THEN unique_click_cnt END) as avg_unique_click_cnt28,
    avg(CASE WHEN sdate BETWEEN '2023-01-01' AND '2023-12-31' THEN unique_click_cnt END) as avg_unique_click_cnt2023,
    avg(CASE WHEN sdate BETWEEN '2022-01-01' AND '2022-12-31' THEN unique_click_cnt END) as avg_unique_click_cnt2022,  
  FROM base_zClick
  GROUP BY zid, zname
),

click_union AS (
  SELECT
    p.*,
    zc.unique_click_cnt28, zc.unique_click_cnt2023, zc.unique_click_cnt2022,
    zc.avg_unique_click_cnt28, zc.avg_unique_click_cnt2023, zc.avg_unique_click_cnt2022
  FROM base_p_union p LEFT JOIN zclick zc ON p.zid = zc.zid
),

base_car AS (
    select
        o.date,
        case when o.zone_id in (105,9890) then 'air' 
            when o.zone_id in (17209) then 'air_infront' else 'common' end as part,
        o.zone_id as zid,
        o.zone_name as zname,
        o.car_id, 
        cl.car_model,

    from `socar-data.socar_biz.operation_per_car_daily_v2` o LEFT JOIN `tianjin_replica.car_info` c ON o.car_id = c.id
                                                             LEFT JOIN `tianjin_replica.car_class` cl ON c.class_id = cl.id
    where o.region1 in ("제주특별자치도") AND date BETWEEN '2022-01-01' AND '2023-12-31'
        and o.sharing_type in ('socar','zplus')
        and o.zone_id not in (122,2184)
    group by date, part,zid,zname, car_id, car_model
    order by date, part,zid
),

car_calc AS (
    SELECT
        zid, zname,
        count(CASE WHEN car_model = '경형' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as ray_28,
        count(CASE WHEN car_model = '준중형' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as K3_28,
        count(CASE WHEN car_model = '중형' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as K5_28,
        count(CASE WHEN car_model = '준대형' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as K8_28,
        count(CASE WHEN car_model = '엔트리SUV' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as casper_28,
        count(CASE WHEN car_model = '소형SUV' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as seltos_28,
        count(CASE WHEN car_model = '준중형SUV' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as spotage_28,
        count(CASE WHEN car_model = '중형SUV' AND date >= current_date('Asia/Seoul') -28 THEN car_id END) as sorento_28,

        count(CASE WHEN car_model = '경형' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as ray_2023,
        count(CASE WHEN car_model = '준중형' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as K3_2023,
        count(CASE WHEN car_model = '중형' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as K5_2023,
        count(CASE WHEN car_model = '준대형' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as K8_2023,
        count(CASE WHEN car_model = '엔트리SUV' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as casper_2023,
        count(CASE WHEN car_model = '소형SUV' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as seltos_2023,
        count(CASE WHEN car_model = '준중형SUV' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as spotage_2023,
        count(CASE WHEN car_model = '중형SUV' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as sorento_2023,

        count(CASE WHEN car_model = '경형' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as ray_2022,
        count(CASE WHEN car_model = '준중형' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as K3_2022,
        count(CASE WHEN car_model = '중형' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as K5_2022,
        count(CASE WHEN car_model = '준대형' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as K8_2022,
        count(CASE WHEN car_model = '엔트리SUV' AND date BETWEEN '2023-01-01' AND '2023-12-31' THEN car_id END) as casper_2022,
        count(CASE WHEN car_model = '소형SUV' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as seltos_2022,
        count(CASE WHEN car_model = '준중형SUV' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as spotage_2022,
        count(CASE WHEN car_model = '중형SUV' AND date BETWEEN '2022-01-01' AND '2022-12-31' THEN car_id END) as sorento_2022,

    FROM base_car
    GROUP BY zid, zname
)

SELECT
  cu.*, 
  cc.* EXCEPT(zid, zname)
FROM click_union cu LEFT JOIN car_calc cc ON cu.zid = cc.zid
ORDER BY zid