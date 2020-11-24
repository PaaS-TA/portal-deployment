#!/bin/bash

# VARIABLES
BOSH_NAME="<BOSH_NAME>"                                # bosh name (e.g. micro-bosh)
IAAS="<IAAS_NAME>"                                     # IaaS (e.g. aws/azure/gcp/openstack/vsphere)
COMMON_VARS_PATH="<COMMON_VARS_FILE_PATH>"             # common_vars.yml File Path (e.g. /home/ubuntu/paasta-5.0/common/common_vars.yml)

# DEPLOY
bosh -e ${BOSH_NAME} -n -d portal-container-infra deploy --no-redact portal-container-infra.yml \
   -l ${COMMON_VARS_PATH} \
   -l vars.yml
