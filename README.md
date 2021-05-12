## 💥 🚨 💥 Notice 💥 🚨 💥
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

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/okpc579"><img src="https://avatars.githubusercontent.com/u/55691511?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Ruby</b></sub></a><br /><a href="https://github.com/PaaS-TA/portal-deployment/commits?author=okpc579" title="Code">💻</a><a href="https://github.com/PaaS-TA/portal-deployment/issues?q=author:okpc579" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://github.com/lena-kim"><img src="https://avatars.githubusercontent.com/u/27713031?v=4?s=100" width="100px;" alt=""/><br /><sub><b>lena-kim</b></sub></a><br /><a href="https://github.com/PaaS-TA/portal-deployment/commits?author=lena-kim" title="Code">💻</a><a href="#ideas-lena-kim" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/jinhyojin"><img src="https://avatars.githubusercontent.com/u/76993633?v=4?s=100" width="100px;" alt=""/><br /><sub><b>jinhyojin</b></sub></a><br /><a href="https://github.com/PaaS-TA/portal-deployment/commits?author=jinhyojin" title="Code">💻</a><a href="#ideas-jinhyojin" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/moonii"><img src="https://avatars.githubusercontent.com/u/12425077?v=4?s=100" width="100px;" alt=""/><br /><sub><b>sunny</b></sub></a><br /><a href="https://github.com/PaaS-TA/portal-deployment/commits?author=moonii" title="Code">💻</a><a href="https://github.com/PaaS-TA/portal-deployment/pulls?q=is&Apr+reviewed-by&moonii" title="Reviewed Pull Requests">👀</a></td>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
