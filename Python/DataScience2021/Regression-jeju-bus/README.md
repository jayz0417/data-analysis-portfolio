# 제주도 대중교통 이용 관광객 예측 프로젝트


![jaemin-don-7ZlXsihxD2c-unsplash](https://user-images.githubusercontent.com/80465347/119299360-bb1a1900-bc99-11eb-908b-789de1220f89.jpg)


제주도를 찾는 관광객들이 선택하는 주요 교통수단은 단연 렌트카이지만, (특히 코로나 19의 여파로) 국내 여행지의 대표인 제주도가 점점 더 각광받으면서 대중교통의 이용 또한 증가하고 있습니다. 
이에 대중교통을 이용하는 관광객의 수를 예측하여 관광지 주변 상권이나 Public Mobile 업체들이 활용할 수 있는 데이터를 만들고자 하였습니다. 

## 1. Project Summary 
### 1.1 목적 
제주 국제 공항 정류장에서 탑승한 탑승객의 수로 대중교통을 이용하는 관광객 수 예측하기 

### 1.2 결과
먼저 데이터상 버스 이용객이 도민인지, 관광객인지를 확실히 알 수 없어 관광지에서 하차하는 인원은 대체로 관광객일 것이라는 가정 하에 권역별로 묶는 작업을 진행하였습니다. 그러나 권역 간 이용량 분포에서 차이점이 뚜렷하게 드러나지 않았으며, 회귀분석 결과 설명력 또한 0.2 정도로 높지 않았습니다. 
이에 접근 방향을 바꾸어 Kmeans clustering을 통해 탑승객이 도민인지 관광객인지를 구분하고자 시도하였습니다. 그 결과 클러스터 간 이용기간 및 횟수, 그리고 주 이용 정류장의 차이가 뚜렷하게 드러나 도민과 관광객의 구분에 성공하였다고 판단하였으며, 관광객으로 추정되는 클러스터의 이용량을 구하여 회귀분석을 진행하자 설명력이 0.6 이상으로 올라가는 결과를 얻었습니다.     

### 1.3 데이터

- 버스 승객별 이용 현황 (2018.07-2019.12) / 제주데이터허브
- 해당 기간의 일별 날씨 데이터 / 기상청 기상자료개방포털

### 1.4 진행순서 

- EDA
- 권역별 그룹핑에 기반한 회귀분석 
- Kmeans Clustering : 탑승객이 관광객인지 도민인지 구분하기 
- 승객 클러스터링에 기반한 회귀분석 

### 1.5 주요 분석 기법 및 사용 툴 

- OLS, Kmeans clustering
- [Pydeck](https://deckgl.readthedocs.io/en/latest/#)

## 2. File List 

-  JejuRegion.py : 권역 그룹핑을 위한 모듈 
-  jeju_datahub_api : 제주데이터허브 API 이용하기 
-  jeju_visualization_map : pydeck을 이용한 제주도 지역별 버스 이용량 시각화  
-  df_regression.csv : regression 용 데이터프레임 파일
-  jeju_clustering.ipynb : 버스 이용객을 대상으로 한 kmeans clustering
-  jeju_regression_part2.ipynb : 회귀분석 


## 3. Contributors

* [정현](https://data-ducky.tistory.com) - 파이덱 시각화 / 회귀분석 / 다스크
* [재훈](https://github.com/jayz0417) - 데이터 전처리 / EDA

## 4. What We Learned, and more... 

- DASK를 사용하면서 필요한 데이터만 가져와서 처리하거나, 최대한 간결하게 작동할 수 있는 코드를 작성하는 등 작업 효율에 대한 고민을 깊게 할 수 있었습니다. 다만 DASK에 적응하는 시간이 소요되면서 프로젝트 착수가 약간 늦어지고, 그만큼 모델 성능 향상을 위한 개선 작업을 단축시켜야 했던 점은 아쉽습니다. 지속적으로 후속 작업들을 이어갈 예정입니다. 
- 추후 제주 지역에서 일레클, ZET와 같은 공유 모빌리티 / 라스트마일 서비스 업체들의 적절한 정류장 위치 선정을 위한 이용자 수 예측이나, 가동률 예측 등 대중교통 이용 관광객 수를 이용한 심화된 프로젝트를 진행해보고 싶습니다.  

## 5. Acknowledgments 

* [Flycode77](https://github.com/FLY-CODE77) /  부족한 질문에도 항상 성실하게 알려주셔서 감사드립니다.  
* [Radajin](https://github.com/radajin) / DASK-KING
* 제주데이터허브, 제주관광협회 / 갑작스러웠던 요청임에도 흔쾌히 데이터를 제공해주셔서 감사드립니다. 
* and [PinkWink](https://github.com/PinkWink) / Kmeans Clustering 제안으로 꽉 막혀있던 프로젝트의 돌파구를 제시하셨습니다.  
