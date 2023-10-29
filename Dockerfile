########################################################################
##  Data Science Basic Environment
########################################################################

FROM debian:latest

ARG username
ARG userpasswd
ARG usermail
ARG userfullname
ARG userid
ARG grpid

LABEL build-date="2023-10-28" \
      name="dsenv" \
      description="Data Science Basic Environment" \
      vcs-ref="" \
      vcs-url="" \
      version="23.10.28"


########################################################################
####  Define External Data Volumes
########################################################################
RUN mkdir -p /shared/notebooks/
RUN mkdir -p /shared/notebooks/db/data
RUN mkdir -p /shared/notebooks/db/ipynb_checkpoints
RUN mkdir -p /shared/notebooks/data/


########################################################################
####  Install basic routines and libraries
########################################################################
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y \
  gnupg \
  curl  \
  git   \
  ffmpeg\
  vim   \
  cmake \
  sudo  \
  build-essential


########################################################################
#### Setup Default User
########################################################################
RUN groupadd ds_users 
RUN groupmod -g $grpid ds_users; exit 0
RUN useradd -rm -d /home/$username -s /bin/bash -g $grpid -G sudo -G ds_users -u $userid $username
WORKDIR /home/$username
RUN chown -R $username /shared


########################################################################
####  Data Science Toolkit
########################################################################

RUN echo $username
RUN ls -l /home/

## data science libraries
RUN apt-get update && apt-get install -y\
    software-properties-common\
    libgeos-dev\
    libgdal-dev\
    libatlas-base-dev\
    r-base \
    r-base-dev

RUN chown -R $username /usr/local/lib/R

# latex & pdf support inside jupyter notebooks
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    keyboard-configuration \
    pandoc \
    texlive-xetex

RUN apt-get update && apt-get install -y openjdk-17-jre openjdk-17-jdk
RUN update-alternatives --config java
RUN update-alternatives --config javac

# install postgresql
RUN apt-get install -y postgresql postgresql-contrib

# user install
USER $username

# # preinstall R packages
RUN R -e "install.packages('shiny')"
RUN R -e "install.packages('rmarkdown')"
RUN R -e "install.packages('plyr')"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('rpart')"
RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('magrittr')"
RUN R -e "install.packages('lubridate')"
RUN R -e "install.packages('scales')"
RUN R -e "install.packages('jsonlite')"
RUN R -e "install.packages('R.utils')"
RUN R -e "install.packages('tools')"
RUN R -e "install.packages('data.table')"

# install miniconda
RUN curl -fsSLO --compressed https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b
ENV PATH /home/${username}/miniconda3/bin:$PATH
RUN bash /home/$username/miniconda3/bin/activate base

# install jupyter lab
RUN conda install python=3.9
RUN conda install -c conda-forge nodejs==18.12.1
RUN conda install -c conda-forge ipywidgets==8.0.2
RUN conda install -c conda-forge jupyterlab
RUN conda install -c conda-forge xeus-python==0.15.1
RUN jupyter labextension install @jupyterlab/debugger
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

RUN jupyter lab clean
RUN jupyter lab build

# python 2 ipython kernel
RUN conda init bash
RUN conda create -n py2 python=2
RUN sh /home/$username/miniconda3/bin/activate py2
RUN python -m ipykernel install --user
RUN sh /home/$username/miniconda3/bin/activate base

# kernel support for R
RUN echo "Installing R kernel"
RUN R -e "install.packages('IRkernel')"
RUN R -e "IRkernel::installspec()"

# # kernel support for Rust

# ## -- uncomment for zmq support in rust:
# ## sudo apt install libzmq3-dev
# ## ENV R_INSTALL_OPTS "--no-default-features"

ENV R_INSTALL_OPTS ""
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.rs
RUN bash rustup.rs -y --no-modify-path
ENV PATH /home/$username/.cargo/bin/:$PATH

### Alternative method:
## RUN cargo install --force --git https://github.com/google/evcxr.git evcxr_jupyter
## RUN rustup component add rust-src
RUN cargo install evcxr_jupyter
RUN evcxr_jupyter --install

##
## Install Extended dependencies
##
RUN pip install --upgrade pip
RUN mkdir /home/$username/dependencies/

ADD ./dependencies/python.core.txt /home/$username/dependencies/python.core.txt
RUN pip install -r /home/$username/dependencies/python.core.txt

ADD ./dependencies/python.ext.txt /home/$username/dependencies/python.ext.txt
RUN pip install -r /home/$username/dependencies/python.ext.txt

RUN pip install torch==2.1.0+cu118 -f https://download.pytorch.org/whl/torch_stable.html
#RUN pip install torchvision==0.16.1+cu117 -f https://download.pytorch.org/whl/torch_stable.html
#RUN pip install torchaudio==0.15.1+cu117 -f https://download.pytorch.org/whl/torch_stable.html

#
# Download pre-trained models parameters
#
# NLTK
RUN echo "Install NLTK models"
RUN python -c "import nltk; nltk.download('stopwords'); nltk.download('punkt'); nltk.download('wordnet')"

# ## FLAIR
# # RUN echo "Install Flair models"
# # RUN python -c "from flair.embeddings import BertEmbeddings; BertEmbeddings('bert-base-cased')"
# # RUN python -c "from flair.models import SequenceTagger; SequenceTagger.load('ner')"

# ##
# ## GENSIM
# ##   Removed unused models:
# ##     - fasttext-wiki-news-subwords-300
# ##     - glove-twitter-200
# ##
# #RUN echo "Install Gensim models"
# #RUN  python -c \
# # "import gensim.downloader as api;\
# #  api.load('glove-twitter-25',  True);"

## SPACY
#RUN echo "Install spaCy models"
#RUN python -m spacy download en_core_web_sm

## Extra Dependencies / Experimentals
RUN pip install faker==15.3.*
RUN pip install transformers==4.25.*

# # ########################################################################
# # ####  SSH Keys SETUP
# # ####  Note that:
# # ####      - id_rsa should have permission flags=600
# # ####      - id_rsa_pub should have permission flags=644
# # ########################################################################

RUN echo "Adding GIT keys"

## Map runtime folder for jupyter
ADD ./tmp/runtime /home/$username/.local/share/jupyter/runtime/

ADD ./keys/id_rsa_git.pub /home/$username/.ssh/id_rsa.pub
ADD ./keys/id_rsa_git /home/$username/.ssh/id_rsa
RUN git config --global user.email $usermail
RUN git config --global user.name $userfullname

USER root
RUN curl -OL https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
RUN tar -C /usr/local -xvf go1.19.4.linux-amd64.tar.gz

USER $username
ENV PATH "$PATH:/usr/local/go/bin"
ENV GO111MODULE "on"
RUN go install github.com/gopherdata/gophernotes@v0.7.5
RUN mkdir -p /home/$username/.local/share/jupyter/kernels/gophernotes
RUN cd /home/$username/.local/share/jupyter/kernels/gophernotes && cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/*  "." && chmod +w ./kernel.json  && sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

USER root

RUN echo $username:$userpasswd | chpasswd
RUN chown -R $username /home/$username/.ssh
RUN chown -R $username /home/$username/.local

ADD bin/entrypoint.sh /entrypoint.sh
RUN sed -i s/%%username%%/$username/g /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chown $username /entrypoint.sh
USER $username

########################################################################
##  Paths & Environment
##
##  NB: In case AMD EPYC 7452 we have to force limit of
##    processor cores being utilized for the performance
##    improvement purposes, set: 
##     ENV NUMEXPR_MAX_THREADS 12
##     ENV OMP_NUM_THREADS 12
########################################################################

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
ENV PATH /home/$username/miniconda3/bin:$PATH

# setup pyspark-specific env
ENV PYSPARK_DRIVER_PYTHON "python3.9"
ENV PYSPARK_PYTHON "python3.9"
RUN echo "export PATH=$PATH" >> /home/$username/.bashrc

ENTRYPOINT [ "/entrypoint.sh" ]

