-- 관리블락 확인용 쿼리 // 운영상 불필요한 차량 예약 조회

SELECT 
  ri.zone_id, ci.zone_name, ci.region1, ri.car_id,  
  ri.id as reservation_id,
  CASE WHEN ri.member_imaginary = 0 THEN '일반' 
       WHEN ri.member_imaginary = 1 THEN '둘러보기'
       WHEN ri.member_imaginary = 2 THEN '테스트'
       WHEN ri.member_imaginary = 3 THEN '관리자'
       WHEN ri.member_imaginary = 4 THEN '일반블락'
       WHEN ri.member_imaginary = 5 THEN '회송'
       WHEN ri.member_imaginary = 6 THEN '사고블락'
       WHEN ri.member_imaginary = 7 THEN '세차'
       WHEN ri.member_imaginary = 8 THEN '협력사' 
       WHEN ri.member_imaginary = 9 THEN '쏘팸'
       WHEN ri.member_imaginary = 10 THEN '독수리'
       WHEN ri.member_imaginary = 11 THEN '검사대행'
       WHEN ri.member_imaginary = 12 THEN '장기블락'
       WHEN ri.member_imaginary = 13 THEN '사고대측'
       WHEN ri.member_imaginary = 14 THEN '타다블락'
       WHEN ri.member_imaginary = 15 THEN '페어링게스트블락'
       WHEN ri.member_imaginary = 16 THEN '페어링오너블락'
       WHEN ri.member_imaginary = 17 THEN '플랜블락'
       WHEN ri.member_imaginary = 18 THEN '타다 드라이버' ELSE cast(ri.member_imaginary as string) END as reservation_type,
  ri.created_at, ri.start_at, ri.end_at, 
  CASE WHEN ri.state = 0 THEN '취소'
       WHEN ri.state = 1 THEN '예약'
       WHEN ri.state = 2 THEN '운행중'
       WHEN ri.state = 3 THEN '완료'
       WHEN ri.state = 4 THEN '고객대기중'
       WHEN ri.state = 5 THEN '반납지연'
       WHEN ri.state = 6 THEN '보류'
       WHEN ri.state = 7 THEN '판매대기중'
       WHEN ri.state = 8 THEN '셍성실패' ELSE cast(ri.state as string) END as reservation_state,
    
  CASE WHEN ri.channel = 'admin' THEN '관리자' ELSE '관리자외' END as channel,
  rm.memo as reservation_memo
FROM `socar-data.tianjin_replica.reservation_info` ri LEFT JOIN `tianjin_replica.carzone_info` ci ON ri.zone_id = ci.id
                                                      LEFT JOIN tianjin_replica.reservation_memo rm ON ri.id = rm.info_key
WHERE DATE(ri.created_at) = current_date('Asia/Seoul') AND ci.region1 = '제주특별자치도' AND ri.member_imaginary IN (2, 4, 6, 12) AND ri.state NOT IN (0, 3, 8)
ORDER BY reservation_id