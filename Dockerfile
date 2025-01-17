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

LABEL build-date="2024-11-21" \
      name="dsenv" \
      description="Data Science Environment" \
      vcs-ref="" \
      vcs-url="" \
      version="24.11.21"

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
  sudo  \
  vim   \
  git   \
  cmake

RUN apt-get install -y \
  ffmpeg\
  flac

RUN apt-get update && apt-get install -y \
  build-essential\
  openjdk-17-jre\
  openjdk-17-jdk

RUN update-alternatives --config java
RUN update-alternatives --config javac


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

## install miniconda
#RUN curl -fsSLO --compressed https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
ENV CONDA_INSTALLER Miniconda3-py312_24.9.2-0-Linux-x86_64.sh
RUN curl -fsSLO --compressed https://repo.anaconda.com/miniconda/${CONDA_INSTALLER}
RUN bash ${CONDA_INSTALLER} -b
ENV PATH /home/${username}/miniconda3/bin:$PATH
RUN bash /home/$username/miniconda3/bin/activate base


# install jupyter lab
RUN conda install python=3.11
#RUN conda install -c conda-forge nodejs==22.11.0
RUN conda install -c conda-forge jupyterlab==4.3.1
RUN conda install -c conda-forge ipywidgets

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
#RUN cargo install --force --git https://github.com/google/evcxr.git evcxr_jupyter
#RUN rustup component add rust-src
RUN cargo install --locked evcxr_jupyter
RUN evcxr_jupyter --install

##
## Install Extended dependencies
##
RUN pip install --no-cache-dir  --upgrade pip


# system
RUN pip install Cython==3.0.9 click==8.1.7 PyYAML==6.0.2 psutil==6.1.0 selenium==4.26.1

# jupyter extensions
RUN pip install jupyter-resource-usage==1.1.0 tqdm==4.67.0

# data preparation / preprocessing
RUN pip install pyspark==3.5.3 pyarrow==18.0.0 ydata-profiling==4.12.0 polars==1.14.0
RUN pip install pandas==2.2.3 xlrd==2.0.1
RUN pip install geopandas==1.0.1 rasterio==1.4.2 faker==33.0.*

# classic ml
RUN pip install nltk==3.9.1 scipy==1.14.1 scikit-learn==1.5.2
RUN pip install category_encoders==2.6.4 catboost==1.2.7  lightgbm==4.5.0 xgboost==2.1.2

# neural networks / linalg
#RUN pip install torch==2.5.1+cu121 torchvision==0.20.1+cu121 torchaudio==2.5.1+cu121 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1
RUN pip install tensorflow==2.18.0 autoawq==0.2.7.* transformers==4.46.3
RUN pip install spacy==3.8.2 accelerate==1.1.1 pytorch-lightning==2.4.0 diffusers==0.31.0

#visualisation & misc
RUN pip install bokeh==3.6.1 seaborn==0.13.2 matplotlib==3.9.2 networkx==3.4.2 kaggle==1.6.17

## pre-init some libraries
# nltk
RUN echo "Install nltk models"\
  && python -c "import nltk; nltk.download('stopwords'); nltk.download('punkt'); nltk.download('wordnet')"
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

RUN python -m spacy download en_core_web_sm\
 && python -m spacy download ru_core_news_sm\
 && python -m spacy download ru_core_news_lg

## Extra Dependencies / Experimentals
RUN mkdir /home/$username/dependencies/

ADD ./dependencies/python.core.txt /home/$username/dependencies/python.core.txt
RUN pip install --no-cache-dir -r /home/$username/dependencies/python.core.txt

ADD ./dependencies/python.ext.txt /home/$username/dependencies/python.ext.txt
RUN pip install --no-cache-dir -r /home/$username/dependencies/python.ext.txt


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

RUN chown -R $username /home/$username/.ssh && chown -R $username /home/$username/.local

ADD bin/entrypoint.sh /entrypoint.sh
RUN sed -i s/%%username%%/$username/g /entrypoint.sh\
  && chmod +x /entrypoint.sh\
  && chown $username /entrypoint.sh
RUN usermod -p $userpasswd $username

RUN curl -OL https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
RUN tar -C /usr/local -xvf go1.23.2.linux-amd64.tar.gz
ENV PATH "$PATH:/usr/local/go/bin"
RUN go install github.com/janpfeifer/gonb@latest
RUN go install golang.org/x/tools/cmd/goimports@latest
RUN go install golang.org/x/tools/gopls@latest
USER $username

ENV PATH "$PATH:/usr/local/go/bin"


#ENV GO111MODULE "on"
#RUN go install github.com/gopherdata/gophernotes@v0.7.5
#RUN mkdir -p /home/$username/.local/share/jupyter/kernels/gophernotes
#RUN cd /home/$username/.local/share/jupyter/kernels/gophernotes && cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/*  "." && chmod +w ./kernel.json  && sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

########################################################################
##  Paths & Environment
##
##  NB: In case AMD EPYC 7452 we have to force limit of
##    processor cores being utilized for the performance
##    improvement purposes, set: 
##     ENV NUMEXPR_MAX_THREADS 12
##     ENV OMP_NUM_THREADS 12
########################################################################

ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64/
ENV PATH /home/$username/miniconda3/bin:$PATH

# setup pyspark-specific env
ENV PYSPARK_DRIVER_PYTHON "python3.9"
ENV PYSPARK_PYTHON "python3.9"
# ENV HF_HOME "/shared/notebooks/db/dl_models"
RUN echo "export PATH=$PATH" >> /home/$username/.bashrc
RUN echo "export LD_LIBRARY_PATH=$CUDA_LIB_PATH:$LD_LIBRARY_PATH"

ENTRYPOINT [ "/entrypoint.sh" ]

