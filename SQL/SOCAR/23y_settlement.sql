-- 23y 연말 성과분석용 쿼리

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
); 

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
    sum(nuse_z2d_oneway) as use_z_oneway,
    sum(cost_parking_zone) as parking_fee,
    sum(cost_transport_mobility) as transport_fee

  FROM    `socar_biz_profit.profit_socar_car_daily` p 
  left join `tianjin_replica.carzone_info` z on p.zone_id=z.id
  WHERE TRUE AND car_sharing_type IN ('socar', 'zplus')
             AND date BETWEEN '2022-01-01' AND current_date('Asia/Seoul')
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
    avg(opr_day) as opr_day,
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
    sum(use_z_oneway) as use_z_oneway,
    sum(parking_fee) as parking_fee,
    sum(transport_fee) as transport_fee
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
    avg(opr_day) as opr_day,
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
    sum(use_z_oneway) as use_z_oneway,    
    sum(parking_fee) as parking_fee,
    sum(transport_fee) as transport_fee
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
    avg(opr_day) as opr_day,
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
    sum(use_z_oneway) as use_z_oneway,
    sum(parking_fee) as parking_fee,
    sum(transport_fee) as transport_fee
  FROM base_p
  WHERE date >= '2022-01-01'
  GROUP BY part, part2, zid, zname
),

base_p_union AS (
  SELECT
    g.*,
    p28.op_rate28, p28.dur_use28, p28.revenue_car28, profit_car28, p28.opr_day as opr_28, p28.parking_fee as parking_fee28, p28.transport_fee as transport_fee28,
    p23.op_rate2023, p23.dur_use2023, p23.revenue_car2023, p23.profit_car2023, p23.opr_day as opr_23, p23.parking_fee as parking_fee23, p23.transport_fee as transport_fee23,
    p22.op_rate2022, p22.dur_use2022, p22.revenue_car2022, p22.profit_car2022, p22.opr_day as opr_22, p22.parking_fee as parking_fee22, p22.transport_fee as transport_fee22,



  FROM base_geo g LEFT JOIN p_28 p28 ON g.zid = p28.zid
                  LEFT JOIN p_2023 p23 ON g.zid = p23.zid
                  LEFT JOIN p_2022 p22 ON g.zid = p22.zid
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
    avg(CASE WHEN sdate >= current_date('Asia/Seoul')-28 THEN unique_click_cnt END) as avg_unique_click_cnt28,
    avg(CASE WHEN sdate BETWEEN '2023-01-01' AND '2023-12-31' THEN unique_click_cnt END) as avg_unique_click_cnt2023,
    avg(CASE WHEN sdate BETWEEN '2022-01-01' AND '2022-12-31' THEN unique_click_cnt END) as avg_unique_click_cnt2022,  
  FROM base_zClick
  GROUP BY zid, zname
),

click_union AS (
  SELECT
    p.*,
    zc.avg_unique_click_cnt28, zc.avg_unique_click_cnt2023, zc.avg_unique_click_cnt2022
  FROM base_p_union p LEFT JOIN zclick zc ON p.zid = zc.zid
),

base_loc AS (
  WITH tmp AS (
  SELECT
    TDDATE,
    callerLog.memberId AS member_id,
    DATETIME(TIMESTAMP_TRUNC(timeMs, SECOND), "Asia/Seoul") AS created_at_kst,
    locationAction.location.lng AS lng,
    locationAction.location.lat AS lat,
  FROM
    `socar_server_2.SAVE_LOCATION_ACTION_LOG`
  WHERE
    locationAction.viewAction="RESERVED_CAR_RENTAL"
    AND fullAccuracyLocationLog.isFullAccuracyLocation IS TRUE
    AND TIMESTAMP_TRUNC(timeMs, DAY) BETWEEN TIMESTAMP("2022-01-01") AND TIMESTAMP("2022-12-31")
  ),

  rv AS (
    SELECT
      id AS reservation_id,
      member_id,
      DATETIME(created_at, "Asia/Seoul") AS created_at_kst,
      zone_id
    FROM `tianjin_replica.reservation_info`
    WHERE
      member_imaginary IN (0, 9)
      AND state IN (1,2,3)
      AND DATE(created_at, 'Asia/Seoul') BETWEEN DATE('2022-01-01') AND DATE('2022-12-31')
  ),

  loc2022 AS (
    SELECT
      rv.reservation_id as rid,
      rv.member_id  as mid,
      cast(rv.created_at_kst as datetime) as created_at,
      rv.zone_id,
      tmp.lat,
      tmp.lng,
      z.lat as zone_lat, 
      z.lng as zone_lng
    FROM rv
    LEFT JOIN tmp
    USING (member_id, created_at_kst)
    LEFT JOIN `tianjin_replica.carzone_info` z ON rv.zone_id = z.id
    WHERE tmp.lat is not null
    AND z.region1 = '제주특별자치도'
    AND z.state = 1
  ),

  loc2023 AS (
    SELECT
      date as rdate,
      reservation_id as rid,
      member_id as mid,
      zone_id,
      zone_lat, zone_lng,
      reservation_created_lng as lng,
      reservation_created_lat as lat,
      cast(reservation_created_at as datetime) as created_at,
    FROM `socar_data_queries_zone_stat_viz_mart.zsv_obt` a 
    LEFT JOIN `tianjin_replica.carzone_info` z ON a.zone_id = z.id
    WHERE extract(year FROM reservation_created_at) = 2023
    AND reservation_created_lng is not null
    AND z.region1 = '제주특별자치도'
    AND z.state = 1
  ),

  base_total AS (
    SELECT * FROM loc2022
    UNION ALL
    SELECT rid, mid, created_at, zone_id, lat, lng, zone_lat, zone_lng FROM loc2023
    ORDER BY created_at desc
  ),

  d300 AS (
    SELECT
      zone_id as zid, 
      z.zone_name as zname,
      count(CASE WHEN date(base_total.created_at) >= current_date('Asia/Seoul') -28 THEN mid ENd) as member_cnt28,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2023-01-01' AND '2023-12-31' THEN mid ENd) as member_cnt23,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2022-01-01' AND '2022-12-31' THEN mid ENd) as member_cnt22,
    FROM base_total LEFT JOIN `tianjin_replica.carzone_info` z ON base_total.zone_id = z.id
    WHERE ST_DISTANCE(ST_GeogPoint(zone_lng, zone_lat), ST_Geogpoint(base_total.lng, base_total.lat)) <= 300
    GROUP BY zid, zname 
  ),

  d500 AS (
    SELECT
      zone_id as zid, 
      z.zone_name as zname,
      count(CASE WHEN date(base_total.created_at) >= current_date('Asia/Seoul') -28 THEN mid ENd) as member_cnt28,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2023-01-01' AND '2023-12-31' THEN mid ENd) as member_cnt23,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2022-01-01' AND '2022-12-31' THEN mid ENd) as member_cnt22,
    FROM base_total LEFT JOIN `tianjin_replica.carzone_info` z ON base_total.zone_id = z.id
    WHERE ST_DISTANCE(ST_GeogPoint(zone_lng, zone_lat), ST_Geogpoint(base_total.lng, base_total.lat)) <= 500
    GROUP BY zid, zname 
  ),

  d1000 AS (
    SELECT
      zone_id as zid, 
      z.zone_name as zname,
      count(CASE WHEN date(base_total.created_at) >= current_date('Asia/Seoul') -28 THEN mid ENd) as member_cnt28,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2023-01-01' AND '2023-12-31' THEN mid ENd) as member_cnt23,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2022-01-01' AND '2022-12-31' THEN mid ENd) as member_cnt22,
    FROM base_total LEFT JOIN `tianjin_replica.carzone_info` z ON base_total.zone_id = z.id
    WHERE ST_DISTANCE(ST_GeogPoint(zone_lng, zone_lat), ST_Geogpoint(base_total.lng, base_total.lat)) <= 1000
    GROUP BY zid, zname 
  ),

  d1000o AS (
    SELECT
      zone_id as zid, 
      z.zone_name as zname,
      count(CASE WHEN date(base_total.created_at) >= current_date('Asia/Seoul') -28 THEN mid ENd) as member_cnt28,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2023-01-01' AND '2023-12-31' THEN mid ENd) as member_cnt23,
      count(CASE WHEN date(base_total.created_at) BETWEEN '2022-01-01' AND '2022-12-31' THEN mid ENd) as member_cnt22,
    FROM base_total LEFT JOIN `tianjin_replica.carzone_info` z ON base_total.zone_id = z.id
    WHERE ST_DISTANCE(ST_GeogPoint(zone_lng, zone_lat), ST_Geogpoint(base_total.lng, base_total.lat)) > 1000
    GROUP BY zid, zname 
  )

  SELECT
    d3.zid, d3.zname,
    d3.member_cnt28 as member300_28, d3.member_cnt23 as member300_23, d3.member_cnt22 as member300_23,
    d5.member_cnt28 as member500_28, d5.member_cnt23 as member500_23, d5.member_cnt22 as member500_23,
    d10.member_cnt28 as member1000_28, d10.member_cnt23 as member1000_23, d10.member_cnt22 as member1000_23,
    d100.member_cnt28 as member1000o_28, d100.member_cnt23 as member1000o_23, d100.member_cnt22 as member1000o_23,

  FROM d300 d3 LEFT JOIN d500 d5 USING (zid, zname)
              LEFT JOIN d1000 d10 USING (zid, zname)
              LEFT JOIN d1000o d100 USING (zid, zname)
)

SELECT
  cu.*, 
  bc.* EXCEPT (zid, zname)
FROM click_union cu
LEFT JOIN base_loc bc ON cu.zid = bc.zid
ORDER BY zid