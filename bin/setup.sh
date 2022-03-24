#!/bin/bash

source `dirname $0`/env.sh

if [[ -z "$DEVENV_HOME" ]]; then
  echo "Fatal: Notebooks home directory is not set: DEVENV_NOTEBOOKS_HOME"
  exit 1
fi

echo "[Step 1]: Generate ssl cert/key for https support"
mkdir -p ${DEVENV_HOME}/tmp/runtime
rm -f ${DEVENV_HOME}/tmp/runtime/mykey.key
rm -f ${DEVENV_HOME}/tmp/runtime/mycert.pem
rm -f ${DEVENV_HOME}/tmp/notebook_cookie_secret
touch -f ${DEVENV_HOME}/tmp/notebook_cookie_secret
chown ${DEVENV_USERID} ${DEVENV_HOME}/tmp/notebook_cookie_secret

openssl req -newkey rsa:2048 -nodes -keyout ${DEVENV_HOME}/tmp/runtime/mykey.key\
            -x509 -days 365 -out ${DEVENV_HOME}/tmp/runtime/mycert.pem

chown ${DEVENV_USERID} ${DEVENV_HOME}/tmp/runtime/mykey.key
chown ${DEVENV_USERID} ${DEVENV_HOME}/tmp/runtime/mycert.pem

echo "[Step 2]: Build docker image"
cd $DEVENV_HOME && bash bin/rebuild.sh 

echo
echo "Done!"
