### 들어가기에 앞서
---
사용 Tool: Bigquery(데이터 임포트), Python(분석)
---   
설명   
```
1.기업의 HR 데이터를 분석하여 인사 데이터를 분석하는 경험과 인사이트를 도출하는 과정을 경험
2.분석의 주요 목적은 퇴사를 촉발하는 요인을 이해하고, 퇴사를 방지할 수 있는 방안을 개발하는 것
```


목적:      
HR 데이터를 분석하여 퇴사를 하는 직원들의 특징을 이해하여 퇴사를 유발하는 요인을 찾아 방지할 수 있는 방법을 제안
---

>개요:

```
1.분석은 데이터 전처리, 탐색적 데이터 분석(EDA), 퇴사 유발 요인 분석 단계로 나누어 진행
2. 수치형/범주형 변수와 퇴직을 시각화하여 비교
3. 다변량 분석으로 특정 변수들이 퇴직에 미치는 영향을 비교
4. 상관관계 분석으로 퇴직에 주는 영향이 높은 요인을 분석
5. 가설 수립후 검증하여 결론 도출
```

---
>문제:
퇴사를 촉발하는 명확인 요인을 찾는 것은 어렵다(1차 EDA)

1. EDA(시각화)
- 수치형 변수
```
 수치형 변수의 분포를 시각화하고, 목표 변수와의 관계를 분석
 20~30대 직원들의 분포가 많음
 ```
<img width="678" alt="나이 분포도" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/0dc0ecfa-1994-4b7e-9cdb-12bf308c8c55">

- 범주형 변수
```
범주형 변수의 분포와, 목표 변수와의 관계를 시각화
  - 부서별 직원 수 구성비:
    - Sales = 31%
    - Research & Development = 65%
    - Human Resources = 4%
```
<img width="680" alt="부서별 직원 현황" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/887b7d8e-ee8c-41d0-a3b1-559e0454d66f">

  ```
  결혼 상태와 퇴직 여부:
    - 기혼자 대비 미혼자의 퇴사가 더 높음
  ```
  <img width="684" alt="기혼여부에 따른 퇴직 여부" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/31695007-9dd6-4d4a-a169-9ff615fb71bc">


- 다변량 분석: 변수 간의 관계를 탐색하며, 두 개 이상의 변수가 Attrition에 미치는 영향을 분석  

  ```
  교육수준, 월소득, 교육수준:
    - 교육수준이 높고 나이가 높을 수록 월 소득은 높음
  - 직무 만족도 & 참여도 관련:
    - 직무 만족도,업무 참여도와 퇴사는 크게 영향 없음
  ```

  <img width="675" alt="연령과 소득 교육 수준에 따른 직원 현황 스캐터플랏" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/44f80406-6d64-4310-afe0-fcda01345df6">

- 상관관계 분석: 상위 10개로 축소하여 드릴다운
  ```
  주요 상관관계도:
    - 현재 직무기간: 근속년수(+0.7), 현재 상사와 근무기간(+0.7)   
    - 스톡옵션정도: 기혼여부(-0.7)    
    - 연봉인상률: 업무성과도(+0.8)   
    - 연령: 월소득(+0.5), 총근속년수(+0.7), 업무강도(+0.5)  
  ```
  <img width="1237" alt="상관관계 매트릭스" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/08ebb352-96c8-4c3a-9f3e-2c21655f2cdf">



---
>해결:   
퇴사자들의 특징으로 퇴사 요인을 유추해본다(2차 EDA)

- 2차 EDA : 퇴사를 촉발하는 요인 찾아보기

| Variable                    | Correlation |
|-----------------------------|-------------|
| Attrition                   | 1.000000    |
| OverTime                    | 0.246118    |
| TotalWorkingYears           | 0.171063    |
| JobLevel                    | 0.169105    |
| MaritalStatus               | 0.162070    |
| YearsInCurrentRole          | 0.160545    |
| MonthlyIncome               | 0.159840    |
| Age                         | 0.159205    |
| YearsWithCurrManager        | 0.156199    |
| StockOptionLevel            | 0.137145    |
| YearsAtCompany      

  - 상관관계가 높은 상위 10개 변수 추출  
  ```
    'OverTime', 'TotalWorkingYears', 'JobLevel', 'MaritalStatus', 'YearsInCurrentRole', 'MonthlyIncome', 'Age', 'YearsWithCurrManager', 'StockOptionLev        | 0.134392    |el', 'YearsAtCompany'
   ```


  - 상위 10개 변수와 퇴사와의 관계 시각화   
  : 업무강도, 현재 직무기간, 현재 상사와 근무기간, 스톡옵션 정도가 낮을 수록 퇴사자가 많음

  <img width="759" alt="야근 여부에 따른 퇴직 " src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/0967f9a2-57e5-4fb0-bf4b-0a381ad71c87">
<img width="740" alt="경력에 따른 최직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/6d046d46-cb9c-494c-8b6c-2649d348a960">
<img width="758" alt="업무 강도에 따른 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/8713757c-3fd6-47d6-86db-154fb8a5d149">
<img width="748" alt="기혼여부와 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/87dc591b-8a24-40c1-b0f9-78ec781ae84f">
<img width="763" alt="현재 직무 경력과 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/241db4b8-5be5-4f82-a335-c98c1331203f">
<img width="754" alt="월소득과 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/d24bf6c3-97d7-4717-8473-37e12bfc1295">
<img width="748" alt="연령과 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/09ae70e6-5533-4f0f-b22a-2b15c9540ca0">
<img width="762" alt="현재상사와의근무기간과 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/540c6e53-276a-4f53-8819-3ce2c1bb69b4">
<img width="759" alt="스톡옵션 정도와 퇴직 분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/24847827-7b88-4010-881d-7059754e55ec">
<img width="757" alt="근속년수와 퇴직분포" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/d67ccadc-257d-4438-9fe2-226e108f016f">


  - 가설수립: *경력이 낮은 그룹일 수록 퇴사자가 많다는 것을 확인*
    - 사회 초년생일 수록, 회사에 합류한지 얼마안될 수록, 현재 상사와 일한 기간이 짧을 수록 퇴사가 많은 건 아닐까   
    ```
    TotalWorkingYears, YearsInCurrentRole, YearsWithCurrManager, YearsAtCompany와 같은 근속 연수 관련 변수들이 퇴직(Attrition)에 미치는 영향을 분석
    ```
  <img width="760" alt="경력년수별 퇴직자 구성비" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/b7a48560-3477-48a6-bee2-66d6f208220c">
<img width="758" alt="현재직무경력기간별 퇴직자 구성비" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/0836f879-5239-4614-8657-c962a58a03e6">
<img width="766" alt="현재상사와의 근무기간별 퇴직자 구성비" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/26e79a52-3f27-48b0-8572-a87dd6f9e8ba">
<img width="749" alt="근속년수 기간별 퇴직자 구성비" src="https://github.com/jayz0417/data-analysis-portfolio/assets/80396016/8bfb7a37-3680-41f3-9557-cdbcc64873c4">




---
>결과:    
1. 직접적인 퇴사의 요인을 찾는 것은 어려움
2. 퇴직과 어느정도 관계가 있는 요소의 특징: 근속년수 관련 변수
- 낮은 총 경력기간, 적은 현재 직무기간, 적은 현재 상사와 근무기간, 적은 근속년수   
  - 사회초년생들의 퇴사가 많은 것으로 볼 수 있음   
---
>결론:
- 3년차 이하의 직원, 신입사원을 특별 관리하며 커리어 성장 프로그램을 개발하여 경력이 적은 직원과 신입사원의 퇴사를 방지해볼 수 있을 것으로 기대
