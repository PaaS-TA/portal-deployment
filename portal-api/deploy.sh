#!/bin/bash

# VARIABLES
COMMON_VARS_PATH="<COMMON_VARS_FILE_PATH>"             # common_vars.yml File Path (e.g. ../../common/common_vars.yml)
CURRENT_IAAS="${CURRENT_IAAS}"						   # IaaS Information (PaaS-TA에서 제공되는 create-bosh-login.sh 미 사용시 aws/azure/gcp/openstack/vsphere 입력)
BOSH_ENVIRONMENT="${BOSH_ENVIRONMENT}"			 # bosh director alias name (PaaS-TA에서 제공되는 create-bosh-login.sh 미 사용시 bosh envs에서 이름을 확인하여 입력)

# portal-log-api 인스턴스 갯수에 따라 logging service 활성화 여부를 분기한다.
LOG_API_INSTANCE_CNT=`grep 'log_api_instances' vars.yml | cut -d ":" -f2 | cut -d "#" -f1`

# DEPLOY
if [[ ${LOG_API_INSTANCE_CNT} -eq 1 ]]; then
  bosh -e ${BOSH_ENVIRONMENT} -n -d portal-api deploy --no-redact portal-api.yml \
     -o operations/${CURRENT_IAAS}-network.yml \
     -o operations/cce.yml \
     -l ${COMMON_VARS_PATH} \
     -l vars.yml
else
  bosh -e ${BOSH_ENVIRONMENT} -n -d portal-api deploy --no-redact portal-api.yml \
     -o operations/disable-logging-service.yml \
     -o operations/${CURRENT_IAAS}-network.yml \
     -o operations/cce.yml \
     -l ${COMMON_VARS_PATH} \
     -l vars.yml
fi
