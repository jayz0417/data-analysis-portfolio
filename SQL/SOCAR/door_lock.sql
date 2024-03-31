-- 차량 문제어 확인용 쿼리

WITH base AS(
  select
  d,
  k.callerLog.memberId as member,
  datetime(k.timeMs, 'Asia/Seoul') as key_time
from(
  select
    date(r.start_at, 'Asia/Seoul') as d,
    r.member_id as mid,
  from tianjin_replica.reservation_info r, tianjin_replica.carzone_info z
  where r.zone_id = z.id
    and r.state in (1,2,3)
    and r.member_imaginary in (0,9)
    and r.way in ('round', 'd2d_oneway', 'd2d_round', 'oneway')
    and date(r.start_at, 'Asia/Seoul') >= '2023-05-01'
    and date(r.start_at, 'Asia/Seoul') <= '2023-05-31'
    and z.region1 in ('제주특별자치도')
    and r.zone_id in (105,9890)
  group by d,mid
  )rev
left outer join socar_server_2.LOG_SMART_KEY_EVENT k on k.callerLog.memberId = rev.mid
  and date(k.timeMs, 'Asia/Seoul') = rev.d
group by d, member, key_time
order by d desc, member, key_time
),

base_rank AS (
  SELECT d, member, key_time, row_number() OVER (partition by d, member order by key_time) as rank
  FROM base
)

SELECT *
FROM base_rank
WHERE rank = 1