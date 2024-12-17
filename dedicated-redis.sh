#!/usr/bin/env bash
####################
# Change as needed #
####################

## Although not required, should match the SpinupWP account
SITE_NAME=client_name

## The default redis port is 6379, so this should be incremented by 1 each time
SITE_REDIS_PORT=6382

## The password just ensures that sites don't leak into each other
SITE_REDIS_PASSWORD="abc123"

## Maximum memory, pick a good number for your site
SITE_REDIS_MAX_MEMORY=256M

#########################################
# No additional changes after the above #
#########################################

## Set up some helper variables
REDIS_CONFIG_ROOT=/etc/redis
REDIS_CONFIG_SITE_ROOT=/etc/redis/sites

## This is the default/stock redis config which we'll clone
REDIS_PRIMARY_CONFIG=${REDIS_CONFIG_ROOT}/redis.conf

## This is the file that we'll clone the previous config to
REDIS_INSTANCE_CONFIG_MAIN_FILE=${REDIS_CONFIG_ROOT}/redis.${SITE_NAME}.conf

## Instead of find-and-replace in the config, we're going to include our
## overrides in a dedicated file at the end of the per-site config
REDIS_INSTANCE_CONFIG_OVERRIDES=${REDIS_CONFIG_SITE_ROOT}/overrides.${SITE_NAME}.conf

## Dedicated service file
SYSTEMD_INSTANCE_SERVICE_FILE=/etc/systemd/system/redis-server-${SITE_NAME}.service

## Create the sites folder if it doesn't exist
mkdir -p ${REDIS_CONFIG_SITE_ROOT}

## Clone the stock config
cp ${REDIS_PRIMARY_CONFIG} ${REDIS_INSTANCE_CONFIG_MAIN_FILE}

## Set our overrides
cat > ${REDIS_INSTANCE_CONFIG_OVERRIDES} <<EOL

port ${SITE_REDIS_PORT}
pidfile /var/run/redis/redis-server-${SITE_NAME}.pid
logfile /var/log/redis/redis-server-${SITE_NAME}.log
dbfilename dump-${SITE_NAME}.rdb
maxmemory ${SITE_REDIS_MAX_MEMORY}
maxmemory-policy allkeys-lru
requirepass ${SITE_NAME}
requirepass "${SITE_REDIS_PASSWORD}"
EOL

## Include our overrides at the end
cat >> ${REDIS_INSTANCE_CONFIG_MAIN_FILE} <<EOL

include ${REDIS_INSTANCE_CONFIG_OVERRIDES}

EOL

## Clone the stock service
cp /lib/systemd/system/redis-server.service ${SYSTEMD_INSTANCE_SERVICE_FILE}

## Find-and-replace with site-specific values
sed -i \
    -e "s#Description=Advanced key-value store#Description=Advanced key-value store for ${SITE_NAME}#" \
    -e "s#ExecStart=/usr/bin/redis-server /etc/redis/redis.conf#ExecStart=/usr/bin/redis-server ${REDIS_INSTANCE_CONFIG_MAIN_FILE}#" \
    -e "s#PIDFile=/run/redis/redis-server.pid#PIDFile=/run/redis/redis-server.${SITE_NAME}.pid#" \
    -e "s#Alias=redis.service#Alias=redis-${SITE_NAME}.service#" \
    ${SYSTEMD_INSTANCE_SERVICE_FILE}

## Set required permissions
chown redis:redis ${REDIS_INSTANCE_CONFIG_MAIN_FILE}
chown redis:redis ${REDIS_INSTANCE_CONFIG_OVERRIDES}
chown root:root  ${SYSTEMD_INSTANCE_SERVICE_FILE}

## Enable and start the service
systemctl enable redis-server-${SITE_NAME}.service
systemctl start redis-server-${SITE_NAME}.service

## Test. If this doesn't return PONG, it has failed. You can ignore the password warning.
redis-cli -a "${SITE_REDIS_PASSWORD}" -p ${SITE_REDIS_PORT} ping
