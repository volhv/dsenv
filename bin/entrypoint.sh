#!/bin/bash
set -e

echo "PATH=$PATH"

export JUPYTER_RUNTIME_DIR="/home/me/"

# drop access to myuser and run cmd
exec jupyter-notebook --ip=0.0.0.0 --port=8888\
     --FileCheckpoints.checkpoint_dir=/shared/notebooks/db/ipynb_checkpoints\
     --notebook-dir=/shared/notebooks/\
     --certfile=/home/me/.local/share/jupyter/runtime/mycert.pem\
     --keyfile=/home/me/.local/share/jupyter/runtime/mykey.key
