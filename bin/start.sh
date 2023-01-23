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

docker run -p ${TARGET_PORT}:8888\
   --platform linux/x86_64\
   -v $DEVENV_NOTEBOOKS_HOME:/shared/notebooks\
   -v $DEVENV_HOME/tmp/runtime/:/home/$DEVENV_USER/.local/share/jupyter/runtime/\
   -v $DEVENV_HOME/tmp/notebook_cookie_secret:/home/$DEVENV_USER/notebook_cookie_secret $DOCKER_IMAGE



