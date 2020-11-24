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
