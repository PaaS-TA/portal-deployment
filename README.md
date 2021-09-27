##  Notice
#### 릴리즈의 경로가 http://45.248.73.44/ 에서 https://nextcloud.paas-ta.org/ 로 변경되었습니다  
#### portal-deployment 5.1.0 이하의 버전을 사용할 경우 <br>
#### 해당 경로를 https://nextcloud.paas-ta.org/~ 로 변경이 필요합니다.

## portal-deployment   

### Portal 배포 방식에 따른 deployment 사용
- Bosh를 이용한 VM 배포
  - portal-api & portal-ui 사용
- CF CLI를 이용한 cloudfoundry container 배포
  - portal-container-infra 사용

### Notices   
- Bosh를 이용한 VM 배포
  - portal-deployment >= v5.0.2   
    - Use PAAS-TA-PORTAL-API-RELEASE >= v2.0.1     
    - Use PAAS-TA-PORTAL-UI-RELEASE >= v2.0.1    
  - portal-deployment =< v5.0.1   
    - Use PAAS-TA-PORTAL-API-RELEASE =< v2.0.0      
    - Use PAAS-TA-PORTAL-UI-RELEASE =< v2.0.0    
    
- CF CLI를 이용한 cloudfoundry container 배포
  - portal-deployment >= v5.0.4  
    - Use PAAS-TA-PORTAL-API-RELEASE >= v2.2.0-ctn


## Contributors ✨

<a href="https://github.com/PaaS-TA/portal-deployment/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=PaaS-TA/portal-deployment" />
</a>
