-- 접속자 집계 쿼리

CREATE TEMP FUNCTION set_region(zone_id any TYPE) AS (
  CASE WHEN zone_id IN (737, 12689, 17046, 110, 2819, 2820, 8743, 8744, 10978, 11456, 13744, 13881, 14264, 15322, 16619, 16620, 17020, 17212, 17270, 17378, 10652, 2574, 5828, 8113, 14217, 17053, 17054, 17184, 17145, 12236, 12362, 12583, 14697, 12929, 12930, 17996, 18202, 18203) THEN '공항주변'
       WHEN zone_id IN (10654, 2230, 16618, 17154, 14451, 12703, 18269) THEN '구서귀포'
       WHEN zone_id IN (2341, 2629, 4874, 12661, 11453, 10490, 14430, 14518, 14520, 15304, 16621, 16898, 17465, 114, 14167, 17208, 651, 18204, 18205) THEN '구제주'
       WHEN zone_id IN (879, 14420, 7906, 12762, 13657, 14943, 17196, 17463) THEN '신서귀포'
       WHEN zone_id IN (3967, 3969, 10892, 11165, 12538, 12959, 12858, 12857, 13400, 7288, 11587, 13969, 10391, 12521, 12812, 14757, 16265, 4504, 8539, 8548, 8741, 11884, 13581, 13597, 14361, 14554, 15397, 16363, 16365, 16997, 17185, 13818, 17836, 18151, 17777, 18206) THEN '외곽'
       WHEN zone_id IN (17209) THEN '공항앞'
       WHEN zone_id IN (5894, 12636, 16126, 246, 13606, 16321, 18261) THEN '중문'
       WHEN zone_id IN (105, 9890) THEN '제주공항' ELSE cast(zone_id as string) END
); -- 존 id별 지역 정보 생성 함수


WITH base AS (
	select
			region,
			part,
			sdate,
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
			set_region(zone_id) as part, 
			z.region2 as region
		from socar_server_2.get_car_classes a , tianjin_replica.carzone_info z, unnest(carClasses) c
			
		where true=true and a.zone_id = z.id
                    AND z.id NOT IN(13858, 17651, 17784)
                    #and date(a.event_timestamp,"Asia/Seoul") >= date_sub(current_date("Asia/Seoul"), interval 90 day)
                    and date(a.event_timestamp,"Asia/Seoul") < current_Date("Asia/Seoul")
                    -- and date(a.start_at,"Asia/Seoul") BETWEEN current_date('Asia/Seoul') -28 AND current_date('Asia/Seoul') -1
                    and date(a.start_at,"Asia/Seoul") >= (current_date("Asia/Seoul")) -- 
                    and date(a.start_at,"Asia/Seoul") < (current_date("Asia/Seoul")-21) -- 오늘부터 7일간 예약값 조회
				-- 조회시점에 따라 위 날짜 조건을 조정해야함
		) click #존클릭자수테이블

	join tianjin_replica.member_info m on m.id = click.mid and m.imaginary in (0) #멤버정보(쏘친,쏘팸)
	left join tianjin_replica.reservation_info r on r.member_id = click.mid #예약정보테이블
                                                and r.zone_id = click.zid
                                                and date(r.start_at, "Asia/Seoul") = click.sdate #예약시작과존클릭시작을leftjoin
                                                and r.state in (1,2,3) #예약,운행,완료
                                                and r.way in ('round') #왕복예약

	group by region, part, sdate, zname
	having region in ('제주시','서귀포시')
) -- 로그데이터로부터 존 클릭 수 집계

SELECT 
	w, 
	sdate, region, part,
	unique_click_cnt, rev_cnt
FROM base
ORDER BY w, sdate