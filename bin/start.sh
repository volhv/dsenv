#!/bin/bash

source `dirname $0`/env.sh

if [[ -z "$DEVENV_NOTEBOOKS_HOME" ]]; then
  echo "Fatal: Notebooks home directory is not set: DEVENV_NOTEBOOKS_HOME"
  exit 1
fi

if [[ -z "$DEVENV_HOME" ]]; then
  echo "Fatal: Developer Environment home directory is not set: DEVENV_HOME"
  exit 1
fi

export CACHE_DIR=$DEVENV_HOME/tmp/cache/


mkdir -p $CACHE_DIR\
  && chown -R $DEVENV_USERID:$DEVENV_USERGID $CACHE_DIR

docker run --gpus ${DEVENV_GPUS} -p ${TARGET_PORT}:8888\
   -p 8080:8080\
   -p 8088:8088\
   -v $DEVENV_NOTEBOOKS_HOME:/shared/notebooks\
   -v $CACHE_DIR:/home/$DEVENV_USER/.cache/\
   -v $DEVENV_HOME/tmp/runtime/:/home/$DEVENV_USER/.local/share/jupyter/runtime/\
   -v $DEVENV_HOME/tmp/notebook_cookie_secret:/home/$DEVENV_USER/notebook_cookie_secret $DOCKER_IMAGE


