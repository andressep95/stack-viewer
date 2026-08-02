#!/bin/sh
set -eu

: "${ENVIRONMENT:=unknown}"
: "${CLUSTER_NAME:=unknown}"
: "${BASE_DOMAIN:=unknown}"
: "${POD_NAME:=unknown}"
: "${POD_NAMESPACE:=unknown}"

export ENVIRONMENT CLUSTER_NAME BASE_DOMAIN POD_NAME POD_NAMESPACE

envsubst '${ENVIRONMENT} ${CLUSTER_NAME} ${BASE_DOMAIN} ${POD_NAME} ${POD_NAMESPACE}' \
  < /usr/share/nginx/html/index.html.template \
  > /usr/share/nginx/html/index.html

exec nginx -g 'daemon off;'
