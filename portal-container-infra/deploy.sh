#!/bin/bash

# VARIABLES
COMMON_VARS_PATH="<COMMON_VARS_FILE_PATH>"             # common_vars.yml File Path (e.g. ../../common/common_vars.yml)

# DEPLOY
bosh -e ${BOSH_ENVIRONMENT} -n -d portal-container-infra deploy --no-redact portal-container-infra.yml \
   -l ${COMMON_VARS_PATH} \
   -l vars.yml