#!/bin/bash

export DOCKER_IMAGE="ds:1.0.0"
export TARGET_PORT="8888"

export DEVENV_GPUS=0
export DEVENV_HOME="/home/username"
export DEVENV_NOTEBOOKS_HOME="/home/username/your/code"

export DEVENV_USER="$USER"
export DEVENV_USERID=`id -u`
export DEVENV_USERGID=`id -g`
export DEVENV_PWD=<password>
export DEVENV_USERMAIL="email@example.com"
export DEVENV_USERFULL="User Full Name"
