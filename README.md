# devenv

Development/Research Operating Environment

# Prerequisites

 1. Install Docker:

    https://docs.docker.com/get-docker/

 2. Command line support: **bash**


# Setup

 1. Configure paths in bin/env.sh:

```bash

   #
   # path to the project root directory
   export DEVENV_HOME="/Users/SomeUser/code/devenv"

   #
   # path to the root directory with research notebooks
   export DEVENV_NOTEBOOKS_HOME="/Users/SomeUser/projects/sandbox"

```

 2. Setup cert/key (self-signed)  for jupyter notebook (https support):

```bash

   bin/setup.sh

```

 3. Run docker container with DS environment

```bash

   bin/start.sh

```
