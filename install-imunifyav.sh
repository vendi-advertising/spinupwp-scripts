#!/usr/bin/env bash

# The domain name of your site
IMUNIFY_SITE_DOMAIN=site.example.com

# The optional sub-folder for the install. This should match whatever you
# put into SpinupWP
IMUNIFY_SITE_INSTALL_FOLDER_NAME=imav

# The user and group that the site runs as
IMUNIFY_USER=site_user_name
IMUNIFY_GROUP=${IMUNIFY_USER}

# The PHP version
IMUNIFY_PHP_VERSION=8.3


#########################################
# No additional changes after the above #
#########################################

# Standard install path for SpinupWP
IMUNIFY_SITE_PATH=/sites/${IMUNIFY_SITE_DOMAIN}/files/${IMUNIFY_SITE_INSTALL_FOLDER_NAME}
IMUNIFY_CONFIG_PATH=/etc/sysconfig/imunify360
IMUNIFY_CONFIG_FILE=${IMUNIFY_CONFIG_PATH}/integration.conf


if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root."
  exit
fi

# The config directory
mkdir -p /etc/sysconfig/imunify360

# Create a simple config file
cat >> ${IMUNIFY_CONFIG_FILE} <<EOL

[paths]
ui_path = ${IMUNIFY_SITE_PATH}
ui_path_owner = ${IMUNIFY_USER}:${IMUNIFY_GROUP}

[pam]
service_name = system-auth

EOL

# Imunify requires proc_open and proc_close, so we need to open that for our
# specific version of PHP
sed -i -e 's/proc_open,//;s/proc_close,//' /etc/php/${IMUNIFY_PHP_VERSION}/fpm/php.ini
service php${IMUNIFY_PHP_VERSION}-fpm restart

# Install Imunify
wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh -O imav-deploy.sh
bash imav-deploy.sh

# Drop an auth file generator
IMUNIFY_AUTH_FILE=imunify-login.sh
truncate -s0 ${IMUNIFY_AUTH_FILE}
cat >> ${IMUNIFY_AUTH_FILE} <<EOL
#!/usr/bin/env bash

IMUNIFY_SITE_DOMAIN=${IMUNIFY_SITE_DOMAIN}

if [ "\$EUID" -ne 0 ]
  then echo "This script must be run as root."
  exit
fi

# Generate a token
IMUNIFY_LOGIN_TOKEN="\$(imunify360-agent login get --username root)"
echo "https://\${IMUNIFY_SITE_DOMAIN}/#/login?token=\${IMUNIFY_LOGIN_TOKEN}"
EOL

chmod +x ${IMUNIFY_AUTH_FILE}
bash ${IMUNIFY_AUTH_FILE}
