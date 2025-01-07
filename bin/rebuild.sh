#!/bin/bash

source `dirname $0`/env.sh

if [[ -z "$DEVENV_HOME" ]]; then
  echo "Fatal: Notebooks home directory is not set: DEVENV_HOME"
  exit 1
fi

echo "Build docker image"

echo "Using credentials: userid=$DEVENV_USERID, grpid=$DEVENV_USERGID for $DEVENV_USER"

cd $DEVENV_HOME && docker build -t ${DOCKER_IMAGE}\
  --platform linux/x86_64\
  --build-arg username="$DEVENV_USER"\
  --build-arg userpasswd="$DEVENV_PWD"\
  --build-arg usermail="$DEVENV_USERMAIL"\
  --build-arg userfullname="$DEVENV_USERFULL"\
  --build-arg userid=$DEVENV_USERID --build-arg grpid=$DEVENV_USERGID .


