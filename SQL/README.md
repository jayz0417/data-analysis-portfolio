## SQL 분석 프로젝트
- 데이터분석을 공부한 이후, 첫 커리어로 분석의 기본이라 생각한 SQL을 자유자재로 활용하기 위해 일레클 서비스에서 진행한 경험들에 대한 기록
- SOCAR 실무에서 이용한 데이터 가공 및 전처리 기록

> 나인투원 쏘카일레클: BigQuery, MongoDB, PostgresQL
- 주로 정산, 분석, 데이터마트 기획(뷰테이블 및 스케쥴 쿼리 테이블, 외부 데이터소스를 활용한 데이터세트 구성 등), 대시보드 분석 쿼리로 구성
```
입사 당시부터, SQL을 끝장나게 활용해서 할 수 있는 모든걸 해보고 싶어 지원했음을 어필하여 비록 직무가 데이터 직무는 아니였지만 원없이 다양한 SQL 문법을 경험하며 대시보드를 기획하고 데이터마트를 기획하여 관리한 경험의 기록
```
- 정산과 관련된 SQL
  - transaction_settlement.sql, 3PL_settlement.sql, business_riding.sql, transactio _settlement_postgresQL.sql
- 대시보드와 관련된 SQL
  - operating_center.sql, operating_center_total.sql,
- 분석 SQL
  - product_analysis.sql
- 데이터마트 관련 SQL: 일부 로그데이터 가공 SQL
  - tf_bike_snapshot.sql, tf_riding.sql, user_type_income.sql
 
> 쏘카
```
실무 입장에서 분석을 위하 가공한 쿼리
```
- 실적 분석 SQL
  - 23y12M_car_profit.sql, 23y8M_user.sql, 23y8M_user_chart.sql, 23y_settlement.sql
  - clicks.sql, clicks_wow.sql, d2d_handle_city.sql, pre_op_rate.sql, profit_minus_car.sql, rev_created_loc.sql
- 운영 관련 SQL
  - block_rev.sql, door_lock.sql
