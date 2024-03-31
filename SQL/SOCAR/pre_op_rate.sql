-- 사전 가동률 분석용 쿼리

CREATE TEMP FUNCTION set_region(zone_id any TYPE) AS (
  CASE WHEN zone_id IN (737, 12689, 17046, 110, 2819, 2820, 8743, 8744, 10978, 11456, 13744, 13881, 14264, 15322, 16619, 16620, 17020, 17212, 17270, 17378, 10652, 2574, 5828, 8113, 14217, 17053, 17054, 17184, 17145, 12236, 12362, 12583, 14697, 12929, 12930, 17996, 18202, 18203, 10652, 12689, 12929, 12930) THEN '공항주변'
       WHEN zone_id IN (10654, 2230, 16618, 17154, 14451, 12703, 18269, 12703, 10654) THEN '구서귀포'
       WHEN zone_id IN (651, 737, 2629, 2341, 2629, 4874, 12661, 11453, 10490, 14430, 14518, 14520, 15304, 16621, 16898, 17465, 114, 14167, 17208, 651, 18204, 18205, 4874, 11453, 2341, 18467) THEN '구제주'
       WHEN zone_id IN (879, 14420, 7906, 12762, 13657, 14943, 17196, 17463, 13657, 14943, 879) THEN '신서귀포'
       WHEN zone_id IN (3967, 3969, 10892, 11165, 12538, 12959, 12858, 12857, 13400, 7288, 11587, 13969, 10391, 12521, 12812, 14757, 16265, 4504, 8539, 8548, 8741, 11884, 13581, 13597, 14361, 14554, 15397, 16363, 16365, 16997, 17185, 13818, 17836, 18151, 17777, 18206, 3969, 7288, 12538, 13597, 13818, 13969, 11587, 12959, 14757, 10892, 3967, 1564, 16363, 16365, 15397) THEN '외곽'
       WHEN zone_id IN (17209) THEN '공항앞'
       WHEN zone_id IN (5894, 12636, 16126, 246, 13606, 16321, 18261, 5894) THEN '중문'
       WHEN zone_id IN (18471, 18472, 18473) THEN '실증사업'
       WHEN zone_id IN (105, 9890) THEN '제주공항' ELSE cast(zone_id as string) END
); 

WITH base1 AS (
  SELECT  
  'w-2' as week,
    snapshot_at, date, leadtime_level,
    set_region(os.zone_id) as part, 
    sum(op_min) as op_min,
    sum(dp_min) as dp_min,
    sum(bl_min) as bl_min
  FROM `socar-data.socar_biz_base.operation_per_car_daily_v2_snapshot` os LEFT JOIN `tianjin_replica.carzone_info` z ON os.zone_id = z.id
  WHERE date(snapshot_at) = current_date('Asia/Seoul') -14 AND extract(hour FROM snapshot_at) = 6
                                                          AND date BETWEEN current_date('Asia/Seoul')-14 AND current_date('Asia/Seoul') -7
                                                          AND z.region1 = '제주특별자치도'
  GROUP BY snapshot_at, date, leadtime_level, part
),

base2 AS (
  SELECT  
  'w-1' as week,
    snapshot_at, date, leadtime_level,
    set_region(os.zone_id) as part, 
    sum(op_min) as op_min,
    sum(dp_min) as dp_min,
    sum(bl_min) as bl_min
  FROM `socar-data.socar_biz_base.operation_per_car_daily_v2_snapshot` os LEFT JOIN `tianjin_replica.carzone_info` z ON os.zone_id = z.id
  WHERE date(snapshot_at) = current_date('Asia/Seoul') -7 AND extract(hour FROM snapshot_at) = 6
                                                          AND date BETWEEN current_date('Asia/Seoul')-7 AND current_date('Asia/Seoul') -1
                                                          AND z.region1 = '제주특별자치도'
  GROUP BY snapshot_at, date, leadtime_level, part
),

base3 AS (
  SELECT  
  'w+1' as week,
    snapshot_at, date, leadtime_level,
    set_region(os.zone_id) as part, 
    sum(op_min) as op_min,
    sum(dp_min) as dp_min,
    sum(bl_min) as bl_min
  FROM `socar-data.socar_biz_base.operation_per_car_daily_v2_snapshot` os LEFT JOIN `tianjin_replica.carzone_info` z ON os.zone_id = z.id
  WHERE date(snapshot_at) = current_date('Asia/Seoul') AND extract(hour FROM snapshot_at) = 6
                                                        AND date BETWEEN current_date('Asia/Seoul') AND current_date('Asia/Seoul') +7
                                                        AND z.region1 = '제주특별자치도'
  GROUP BY snapshot_at, date, leadtime_level, part
)

SELECT * FROM base1
UNION ALL
SELECT * FROM base2
UNION ALL
SELECT * FROM base3
ORDER BY date, part