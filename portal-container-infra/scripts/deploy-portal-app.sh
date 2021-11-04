#!/bin/bash

source portal-app-variable.yml

PORTALAPPNAME=portal-app-1.2.1
PORTALAPPDOWNLOADLINK=https://nextcloud.paas-ta.org/index.php/s/LmZTEiJn6NcJoiY/download

#########################################
# Portal Component Folder Name
PORTAL_API=portal-api-2.4.0
PORTAL_COMMON_API=portal-common-api-2.2.0
PORTAL_GATEWAY=portal-gateway-2.1.0
PORTAL_LOG_API=portal-log-api-2.2.0
PORTAL_REGISTRATION=portal-registration-2.1.0
PORTAL_STORAGE_API=portal-storage-api-2.2.1
PORTAL_WEB_ADMIN=portal-web-admin-2.3.0
PORTAL_WEB_USER=portal-web-user-2.3.1
PORTAL_SSH=portal-ssh-1.0.0

#########################################
# Pre-condition check
DOMAIN=$(grep -r "system_domain" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g' )
# bosh login check
bosh env
if [[ "$?" -eq 0 ]] || [[ $(bosh env) == *"not log"* ]] ; then
        echo "bosh login check!"
else
        echo "bosh don't login -> bosh login plz"
        return
fi

#uaac check
uaac --version
if [[ $(uaac --version) == "UAA client"* ]]; then
        echo "uaac installed"
else
        echo "uaac dont installed -> uaac install"
        sudo gem install cf-uaac
        uaac --version
        if [[ "$?" -eq 0 ]] ; then
                echo "uaac install success"
        else
                echo "uaac can't install -> ruby check plz"
                return
        fi
fi

DOMAIN=$(grep -r "system_domain" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
UAA_ADMIN_CLIENT_SECRET=$(grep -r "uaa_client_admin_secret" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
uaac target uaa.$DOMAIN --skip-ssl-validation
uaac token client get $UAA_ADMIN_CLIENT_ID -s $UAA_ADMIN_CLIENT_SECRET
uaac client update $UAAC_PORTAL_CLIENT_ID --redirect_uri "http://portal-web-user."$DOMAIN", http://portal-web-user."$DOMAIN"/callback"


# VARIABLE SETTING
DOMAIN=$(grep -r "system_domain" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g' )
CF_USER_ADMIN_USERNAME=$(grep -r "paasta_admin_username" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
CF_USER_ADMIN_PASSWORD=$(grep -r "paasta_admin_password" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
UAA_ADMIN_CLIENT_SECRET=$(grep -r "uaa_client_admin_secret" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')

## PORTAL DB
if [[ ${IS_PORTAL_EXTERNAL_DB} = "false" ]]; then
        # Portal - Internal DB use
        PORTAL_DB_IP=$(bosh vms -d $PORTAL_INFRA_DEPLOYMENT_NAME | grep $PORTAL_INFRA_DATABASE_NAME | cut -f 4 | sed -e 's/ //g')
        PORTAL_DB_PORT=$(grep -r "mariadb_port" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')
        PORTAL_DB_USER_PASSWORD=$(grep -r "mariadb_admin_password" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')

elif [[ ${IS_PORTAL_EXTERNAL_DB} = "true" ]]; then
        # Portal - External DB use
        PORTAL_DB_IP=$PORTAL_EXTERNAL_DB_IP
        PORTAL_DB_PORT=$PORTAL_EXTERNAL_DB_PORT
        PORTAL_DB_USER_PASSWORD=$PORTAL_EXTERNAL_DB_PASSWORD

else
        # unknown IS_PORTAL_EXTERNAL_DB value
        echo "plz check IS_PORTAL_EXTERNAL_DB"
        return
fi


MONITORING_API_URL=$(grep -r "monitoring_api_url" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')


## AP DB
if [[ ${IS_PAAS_TA_EXTERNAL_DB} = "false" ]]; then
        # AP - Internal DB use
        if [[ -n $(bosh is --ps -d $PAASTA_CORE_DEPLOYMENT_NAME | grep $PAASTA_DATABASE_INSTANCE_NAME | grep "postgres") ]]; then
                PAASTA_DB_DRIVER=org.postgresql.Driver
                PAASTA_DATABASE=postgresql
        elif [[ -n $(bosh is --ps -d $PAASTA_CORE_DEPLOYMENT_NAME | grep $PAASTA_DATABASE_INSTANCE_NAME | grep "pxc") ]]; then
                PAASTA_DB_DRIVER=com.mysql.jdbc.Driver
                PAASTA_DATABASE=mysql
        fi
        PAASTA_DB_IP=$(bosh vms -d $PAASTA_CORE_DEPLOYMENT_NAME | grep $PAASTA_DATABASE_INSTANCE_NAME | cut -f 4 | sed -e 's/ //g')
        PAASTA_DB_PORT=$(grep -r "paasta_database_port" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')

elif [[ ${IS_PAAS_TA_EXTERNAL_DB} = "true" ]]; then
        # AP - External DB use
        if [[ $PAAS_TA_EXTERNAL_DB_KIND = "postgres" ]]; then
                PAASTA_DB_DRIVER=org.postgresql.Driver
                PAASTA_DATABASE=postgresql
        elif [[ $PAAS_TA_EXTERNAL_DB_KIND = "mysql" ]]; then
                PAASTA_DB_DRIVER=com.mysql.jdbc.Driver
                PAASTA_DATABASE=mysql
        else
                echo "plz check IS_PAAS_TA_EXTERNAL_DB & PAAS_TA_EXTERNAL_DB_KIND"
                return
        fi

        PAASTA_DB_IP=$PAAS_TA_EXTERNAL_DB_IP
        PAASTA_DB_PORT=$PAAS_TA_EXTERNAL_DB_PORT
else
        # unknown IS_PAAS_TA_EXTERNAL_DB value
        echo "plz check IS_PAAS_TA_EXTERNAL_DB"
        return
fi

CC_DB_USER_PASSWORD=$(grep -r "paasta_cc_db_password" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
UAA_DB_USER_PASSWORD=$(grep -r "paasta_uaa_db_password" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')
MAIL_SMTP_PROPERTIES_AUTHURL=portal-web-user.$(grep -r "system_domain" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')

## OBJECT STORAGE
if [[ ${IS_PORTAL_EXTERNAL_STORAGE} = "false" ]]; then
        # Portal - Internal Storage use
        OBJECTSTORAGE_TENANTNAME=$(grep -r "binary_storage_tenantname" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')
        OBJECTSTORAGE_USERNAME=$(grep -r "binary_storage_username" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')
        OBJECTSTORAGE_PASSWORD=$(grep -r "binary_storage_password" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')
        OBJECTSTORAGE_IP=$(bosh vms -d $PORTAL_INFRA_DEPLOYMENT_NAME | grep $PORTAL_INFRA_DATABASE_NAME | cut -f 4)
        OBJECTSTORAGE_PORT=$(grep -r "binary_storage_auth_port" $PORTAL_INFRA_VARS_PATH | cut -d ':' -f 2 | cut -d " " -f 2 | sed -e 's/ //g' | sed -e 's/\"//g')

elif [[ ${IS_PORTAL_EXTERNAL_STORAGE} = "true" ]]; then
        # Portal - External Storage use
        OBJECTSTORAGE_TENANTNAME=$PORTAL_EXTERNAL_STORAGE_TENANTNAME
        OBJECTSTORAGE_USERNAME=$PORTAL_EXTERNAL_STORAGE_USERNAME
        OBJECTSTORAGE_PASSWORD=$PORTAL_EXTERNAL_STORAGE_PASSWORD
        OBJECTSTORAGE_IP=$PORTAL_EXTERNAL_STORAGE_IP
        OBJECTSTORAGE_PORT=$PORTAL_EXTERNAL_STORAGE_PORT
else
        # unknown IS_PORTAL_EXTERNAL_STORAGE value
        echo "plz check IS_PORTAL_EXTERNAL_STORAGE"
        return
fi

UAAC_PORTAL_CLIENT_SECRET=$(grep -r "uaa_client_portal_secret" $COMMON_VARS_PATH | cut -d ':' -f 2 | cut -f 1 | sed -e 's/ //g' | sed -e 's/\"//g')


#########################################

CURRENTDIRCTORY=$(pwd)

mkdir $PORTAL_APP_WORKING_DIRECTORY -p
if [ -d $PORTAL_APP_WORKING_DIRECTORY ]; then
        cd $PORTAL_APP_WORKING_DIRECTORY
else
        echo "plz check PORTAL_APP_WORKING_DIRECTORY"
        cd $CURRENTDIRCTORY
        return
fi

# portal-app download
## portal-app zip downloaded check
if [ -e $PORTALAPPNAME.zip ]; then
        echo "portal-app zip file exists - download skip"
else
        echo "portal-app zip file not exists - download zip file "
        ## portal-app wget download
        wget --content-disposition $PORTALAPPDOWNLOADLINK
fi

if [ ! -e $PORTALAPPNAME.zip ]; then
        echo "plz check portal app download link : "$PORTALAPPDOWNLOADLINK
        cd $CURRENTDIRCTORY
        return
fi


#########################################
# portal-app unzip
if [ -d $PORTALAPPNAME ]; then
        echo "portal-app folder exists - delete folder"
        ## existing portal-app directory delete
        ll | grep "$PORTALAPPNAME" | grep ^d | awk '{print $NF}' | xargs rm -rf
fi
## portal-app unzip
echo "portal-app unzip"
unzip $PORTALAPPNAME.zip

#########################################
#config change

if [ -d $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME ]; then
        cd $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME
else
        echo "plz check directory : " $PORTAL_APP_WORKING_DIRECTORY"/"$PORTALAPPNAME
        cd $CURRENTDIRCTORY
        return
fi




## COMMON VARIABLE
# DOMAIN
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_GATEWAY/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_REGISTRATION/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_ADMIN/manifest.yml -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config -type f | xargs sed -i -e 's/<DOMAIN>/'${DOMAIN}'/g'


# CF_USER_ADMIN_USERNAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<CF_USER_ADMIN_USERNAME>/'${CF_USER_ADMIN_USERNAME}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<CF_USER_ADMIN_USERNAME>/'${CF_USER_ADMIN_USERNAME}'/g'

# CF_USER_ADMIN_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<CF_USER_ADMIN_PASSWORD>/'${CF_USER_ADMIN_PASSWORD}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<CF_USER_ADMIN_PASSWORD>/'${CF_USER_ADMIN_PASSWORD}'/g'

# UAA_CLIENT_ID
## UAA_ADMIN_CLIENT_ID == UAA_CLIENT_ID
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'

# UAA_CLIENT_SECRET
## UAA_ADMIN_CLIENT_SECRET == UAA_CLIENT_SECRET
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'

# UAA_ADMIN_CLIENT_ID
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_ADMIN_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_ADMIN_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'

# UAA_ADMIN_CLIENT_SECRET
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_ADMIN_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_ADMIN_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'

# UAA_LOGIN_CLIENT_ID
## UAA_ADMIN_CLIENT_ID == UAA_LOGIN_CLIENT_ID
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_LOGIN_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_LOGIN_CLIENT_ID>/'${UAA_ADMIN_CLIENT_ID}'/g'

# UAA_LOGIN_CLIENT_SECRET
## UAA_ADMIN_CLIENT_SECRET == UAA_LOGIN_CLIENT_SECRET
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_LOGIN_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_LOGIN_CLIENT_SECRET>/'${UAA_ADMIN_CLIENT_SECRET}'/g'

# PORTAL_DB_IP
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_IP>/'${PORTAL_DB_IP}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_ADMIN/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_IP>/'${PORTAL_DB_IP}'/g'

# PORTAL_DB_PORT
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_PORT>/'${PORTAL_DB_PORT}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_ADMIN/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_PORT>/'${PORTAL_DB_PORT}'/g'

# PORTAL_DB_USER_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_USER_PASSWORD>/'${PORTAL_DB_USER_PASSWORD}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_ADMIN/manifest.yml -type f | xargs sed -i -e 's/<PORTAL_DB_USER_PASSWORD>/'${PORTAL_DB_USER_PASSWORD}'/g'

## PORTAL-API
# ABACUS_URL(Deprecated)
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<ABACUS_URL>/'${ABACUS_URL}'/g'
# MONITORING_API_URL
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml -type f | xargs sed -i -e 's/<MONITORING_API_URL>/'${MONITORING_API_URL}'/g'


## PORTAL-COMMON-API
# PAASTA_DB_DRIVER
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PAAS-TA_DB_DRIVER>/'${PAASTA_DB_DRIVER}'/g'

# PAASTA_DATABASE
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PAAS-TA_DATABASE>/'${PAASTA_DATABASE}'/g'

# PAASTA_DB_IP
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e "s/<PAAS-TA_DB_IP>/$PAASTA_DB_IP/g"

# PAASTA_DB_PORT
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<PAAS-TA_DB_PORT>/'${PAASTA_DB_PORT}'/g'

# CC_DB_NAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<CC_DB_NAME>/'${CC_DB_NAME}'/g'

# CC_DB_USER_NAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<CC_DB_USER_NAME>/'${CC_DB_USER_NAME}'/g'

# CC_DB_USER_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<CC_DB_USER_PASSWORD>/'${CC_DB_USER_PASSWORD}'/g'

# UAA_DB_NAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_DB_NAME>/'${UAA_DB_NAME}'/g'

# UAA_DB_USER_NAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_DB_USER_NAME>/'${UAA_DB_USER_NAME}'/g'

# UAA_DB_USER_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<UAA_DB_USER_PASSWORD>/'${UAA_DB_USER_PASSWORD}'/g'

# MAIL_SMTP_HOST
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_HOST>/'${MAIL_SMTP_HOST}'/g'

# MAIL_SMTP_PORT
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_PORT>/'${MAIL_SMTP_PORT}'/g'

# MAIL_SMTP_USERNAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_USERNAME>/'${MAIL_SMTP_USERNAME}'/g'

# MAIL_SMTP_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_PASSWORD>/'${MAIL_SMTP_PASSWORD}'/g'

# MAIL_SMTP_USEREMAIL
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_USEREMAIL>/'${MAIL_SMTP_USEREMAIL}'/g'

# MAIL_SMTP_PROPERTIES_AUTHURL
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml -type f | xargs sed -i -e 's/<MAIL_SMTP_PROPERTIES_AUTHURL>/'${MAIL_SMTP_PROPERTIES_AUTHURL}'/g'

## PORTAL-STORAGE-API
# OBJECTSTORAGE_TENANTNAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<OBJECTSTORAGE_TENANTNAME>/'${OBJECTSTORAGE_TENANTNAME}'/g'

# OBJECTSTORAGE_USERNAME
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<OBJECTSTORAGE_USERNAME>/'${OBJECTSTORAGE_USERNAME}'/g'

# OBJECTSTORAGE_PASSWORD
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<OBJECTSTORAGE_PASSWORD>/'${OBJECTSTORAGE_PASSWORD}'/g'

# OBJECTSTORAGE_IP
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<OBJECTSTORAGE_IP>/'${OBJECTSTORAGE_IP}'/g'

# OBJECTSTORAGE_PORT
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml -type f | xargs sed -i -e 's/<OBJECTSTORAGE_PORT>/'${OBJECTSTORAGE_PORT}'/g'



## PORTAL-WEBUSER
# UAAC_PORTAL_CLIENT_ID
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config -type f | xargs sed -i -e 's/<UAAC_PORTAL_CLIENT_ID>/'${UAAC_PORTAL_CLIENT_ID}'/g'

# UAAC_PORTAL_CLIENT_SECRET
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config -type f | xargs sed -i -e 's/<UAAC_PORTAL_CLIENT_SECRET>/'${UAAC_PORTAL_CLIENT_SECRET}'/g'

# USER_APP_SIZE_MB
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config -type f | xargs sed -i -e 's/<USER_APP_SIZE_MB>/'${USER_APP_SIZE_MB}'/g'

# MONITORING_ENABLE
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config -type f | xargs sed -i -e 's/<MONITORING_ENABLE>/'${MONITORING_ENABLE}'/g'


# PORTAL WEBUSER MAIN
BEFORE_CONFIG=$PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/paas-ta-portal-webuser/assets/resources/env/config.json
AFTER_CONFIG=$PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/config/config.json
MAIN_JS=$PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/paas-ta-portal-webuser/main.*.js

BEFORE_FILTER=$(cat ${BEFORE_CONFIG} | tr -d '{'  |tr -d '\r\n' | tr -d '"' | sed -e 's/: /:\"/g' | sed -e 's/,  /\",/g' | sed -e 's/^ *//g' -e 's/ *$//g' | sed -e 's/}/"/g' | sed -e 's/"false"/!1/g' | sed -e 's/"true"/!0/g'| sed -e 's/\//\\\//g' )
AFTER_FILTER=$(cat ${AFTER_CONFIG} | tr -d '{'  |tr -d '\r\n' | tr -d '"' | sed -e 's/: /:\"/g' | sed -e 's/,  /\",/g' | sed -e 's/^ *//g' -e 's/ *$//g' | sed -e 's/}/"/g' | sed -e 's/"false"/!1/g' | sed -e 's/"true"/!0/g'| sed -e 's/\//\\\//g')

echo "====================================================="
echo "BEFORE :: $BEFORE_FILTER"
echo "====================================================="
echo "AFTER  :: $AFTER_FILTER"
echo "====================================================="

CHANGE_CONFIG="'s/${BEFORE_FILTER}/${AFTER_FILTER}/g' ${MAIN_JS}"

echo $CHANGE_CONFIG | xargs sed -i

cp $AFTER_CONFIG $BEFORE_CONFIG



#SECURITY GROUP
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/portal-rule.json -type f | xargs sed -i -e 's/<PORTAL_DB_IP>/'${PORTAL_DB_IP}'/g'
find $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/portal-rule.json -type f | xargs sed -i -e "s/<PAAS-TA_DB_IP>/$PAASTA_DB_IP/g"



#########################################
# Portal App push


cf login -a https://api.${DOMAIN} --skip-ssl-validation -u ${CF_USER_ADMIN_USERNAME} -p ${CF_USER_ADMIN_PASSWORD} << EOF


EOF

# Create Portal Org, Space
cf create-quota ${PORTAL_QUOTA_NAME} -m 20G -i -1 -s -1 -r -1 --reserved-route-ports -1 --allow-paid-service-plans
cf create-org ${PORTAL_ORG_NAME} -q ${PORTAL_QUOTA_NAME}
cf create-space ${PORTAL_SPACE_NAME} -o ${PORTAL_ORG_NAME}

cf target -o ${PORTAL_ORG_NAME} -s ${PORTAL_SPACE_NAME}


# Create Portal Security Group
cf create-security-group ${PORTAL_SECURITY_GROUP_NAME} $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/portal-rule.json
cf bind-running-security-group ${PORTAL_SECURITY_GROUP_NAME}
cf bind-staging-security-group ${PORTAL_SECURITY_GROUP_NAME}



# Portal APP push
cf push -i $PORTAL_API_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_API/manifest.yml
cf push -i $PORTAL_COMMON_API_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_COMMON_API/manifest.yml
cf push -i $PORTAL_GATEWAY_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_GATEWAY/manifest.yml
cf push -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_LOG_API/manifest.yml
cf push -i $PORTAL_REGISTRATION_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_REGISTRATION/manifest.yml
cf push -i $PORTAL_STORAGE_API_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_STORAGE_API/manifest.yml
cf push -i $PORTAL_WEB_ADMIN_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_ADMIN/manifest.yml
cf push -i $PORTAL_WEB_USER_INSTANCE -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_WEB_USER/manifest.yml
cf push -f $PORTAL_APP_WORKING_DIRECTORY/$PORTALAPPNAME/$PORTAL_SSH/manifest.yml


# tcp port open : portal-log-api
# find APP_GUID
APP_GUID=$(cf app portal-log-api --guid)
echo "$APP_GUID"

# create tcp domain
cf create-shared-domain tail-log.$DOMAIN --router-group default-tcp

# listen port 5555
cf curl /v2/apps/$APP_GUID -X PUT -d '{"ports": [8080, 5555]}'

# map-route tcp 1024
cf map-route portal-log-api tail-log.$DOMAIN --port 1024

# find port 1122 ROUTE_GUID
ROUTE_GUID=$(cf curl /v2/routes?q=port:1024 | grep \"guid\" | awk -F \" '{ print $4 }')
echo "$ROUTE_GUID"

# find route_mapping default port 8080
DEFAULT_ROUTE_GUID=$(cf curl /v2/routes/$ROUTE_GUID/route_mappings | grep \"guid\" | awk -F \" '{ print $4 }')
echo "$DEFAULT_ROUTE_GUID"

# delete route_mapping default port 8080
cf curl /v2/route_mappings/$DEFAULT_ROUTE_GUID -X DELETE -d ''

# add route_mapping app_port 5555
cf curl /v2/route_mappings -X POST -d '{"app_guid": "'"$APP_GUID"'", "route_guid": "'"$ROUTE_GUID"'", "app_port": 5555}'

cf restart portal-log-api

cf apps

cd $CURRENTDIRCTORY
