-- 부름 배반지역 확인용 쿼리 (지역간 이동)

SELECT
  CASE WHEN date(date) BETWEEN '2023-12-28' AND '2024-01-09' THEN 'Before'
       WHEN date(date) BETWEEN '2024-01-10' AND '2024-01-23' THEN 'After' END as date_type,
  -- date, 
  CASE WHEN way = 'd2d_export_h' THEN 'd2d_배차'
        WHEN way = 'd2d_import_h' THEN 'd2d_반차' END as way,
  region2,
  count(reservationId) as cnt,
  count(CASE WHEN start_city ='제주시' AND end_city = '제주시' THEN reservationId END) as JtoJ, 
  count(CASE WHEN start_city ='제주시' AND end_city = '서귀포시' THEN reservationId END) as JtoS,
  count(CASE WHEN start_city ='서귀포시' AND end_city = '서귀포시' THEN reservationId END) as StoS,
  count(CASE WHEN start_city ='서귀포시' AND end_city = '제주시' THEN reservationId END) as StoJ,
FROM (
  SELECT
    r.id AS rid, /* 옥스트라 예약번호 */
    hr.reservationId, -- 핸들 아이디
    r.state, /* 핸들의 상태값 0:취소, 3:완료 */
    r.way,
    z.region2,

    date(r.start_at, "Asia/Seoul") as date,

    CASE WHEN startAddress1 LIKE "%제주시%" THEN '제주시'
        WHEN startAddress1 LIKE "%서귀포시%" THEN '서귀포시' END as start_city,

    CASE WHEN endAddress1 LIKE "%제주시%" THEN '제주시'
        WHEN endAddress1 LIKE "%서귀포시%" THEN '서귀포시' END as end_city,      

            
  FROM `socar-data.tianjin_replica.reservation_info` AS r
  LEFT JOIN `socar-handler.handler_replica.socarhandler_reservation` AS hr /* 핸들러 예약 테이블 (핸들러 배정된 내역만 적재) */
  ON hr.scReservationId = r.id
  LEFT JOIN `tianjin_replica.carzone_info` z ON r.zone_id = z.id
  WHERE r.way in ('d2d_export_h','d2d_import_h') /* d2d_export_h 반차: d2d_import_h 이벤트핸들: handle */
  AND r.state in (3,0) /* 완료&취소 핸들 집계 */
  AND date(r.start_at) BETWEEN '2023-12-28' AND '2024-01-23'
  AND startAddress1 LIKE "%제주특별자치도%"
)
GROUP BY date_type, way, region2
ORDER BY date_type, way, region2