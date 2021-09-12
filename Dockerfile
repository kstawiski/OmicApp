FROM ubuntu
ENV PUBLIC=0

# Basic build setup
ENV DEBIAN_FRONTEND noninteractive
ENV CRAN_URL https://cloud.r-project.org/
ENV TZ=Europe/Warsaw
RUN chsh -s /bin/bash root && echo 'SHELL=/bin/bash' >> /etc/environment && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && apt update && apt dist-upgrade -y && apt-get install -y pciutils libkmod-dev libv8-dev mc gdebi libgit2-dev uuid libglu1-mesa-dev apt-transport-https screen build-essential libxml2-dev xorg ca-certificates cmake curl git libatlas-base-dev libcurl4-openssl-dev libjemalloc-dev liblapack-dev libopenblas-dev libopencv-dev libzmq3-dev software-properties-common sudo unzip wget && add-apt-repository -y ppa:ubuntu-toolchain-r/test && apt update && apt install -y build-essential libmagick++-dev libbz2-dev libpcre2-16-0 libpcre2-32-0 libpcre2-8-0 libpcre2-dev fort77 xorg-dev liblzma-dev  libblas-dev gfortran gcc-multilib gobjc++ libreadline-dev && apt install -y pandoc texinfo texlive-fonts-extra texlive libcairo2-dev freeglut3-dev build-essential libx11-dev libxmu-dev libxi-dev libgl1-mesa-glx libglu1-mesa libglu1-mesa-dev libglfw3-dev libgles2-mesa-dev libopenblas-dev liblapack-dev libopencv-dev build-essential git gcc cmake libcairo2-dev libxml2-dev texlive-full texlive-xetex ttf-mscorefonts-installer build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev default-jre default-jdk && echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Install Anaconda
ENV PATH /opt/conda/bin:$PATH
ENV SHELL /bin/bash
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda
RUN rm Miniconda3-latest-Linux-x86_64.sh &&\
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV TENSORFLOW_PYTHON /opt/conda/bin/python
ENV RETICULATE_PYTHON /opt/conda/bin/python

# Keras, tensorflow, jupyter
RUN apt-get update --fix-missing && \
    apt-get install -y apt-utils libxml2-dev sshfs cifs-utils libffi-dev libx11-dev mesa-common-dev libfreetype6-dev libglu1-mesa-dev libssl-dev wget bzip2 ca-certificates build-essential cmake git unzip pkg-config libopenblas-dev liblapack-dev libhdf5-serial-dev libglib2.0-0 libxext6 libsm6 libxrender1 gfortran-7 gcc-7 libglu1-mesa-dev freeglut3-dev mesa-common-dev && apt-get clean && \
    conda update --all && conda install mamba -c conda-forge && mamba install --channel "conda-forge" --channel "anaconda" --channel "r" tensorflow keras jupyter jupytext numpy pandas opencv && echo "options(repos=structure(c(CRAN='http://cran.r-project.org')))" >> ~/.Rprofile

# R:
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && add-apt-repository -y "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -sc)-cran40/" && apt update && apt -y dist-upgrade && apt install -y r-base-dev texlive-full texlive-xetex ttf-mscorefonts-installer r-recommended build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev default-jre default-jdk && Rscript -e "install.packages(c('remotes','devtools','BiocManager','keras','rgl','rJava'))"

COPY setup/keras.R /
COPY setup/setup.R /

RUN Rscript -e "chooseCRANmirror(ind=1);" && Rscript /setup.R && echo 'root:biostat' | chpasswd 
RUN useradd -m app && echo 'app:OmicSelector' | chpasswd
RUN adduser app sudo && mkdir /home/app/www/ && chown app:app -R /home/app/www/ && mkdir /home/app/modules/ && chown app:app -R /home/app/modules/ && mkdir /home/app/logs/ && chown app:app -R /home/app/logs/ && echo 'export PATH="/opt/conda/bin:$PATH"' >> /home/app/.bashrc

# Setup keras in R env
RUN Rscript /keras.R && Rscript -e "library(OmicSelector);"

# Build
COPY setup/entrypoint.sh /entrypoint.sh
RUN chsh -s /bin/bash && echo 'export PATH="/opt/conda/bin:$PATH"' >> ~/.bashrc && apt-get install -y --reinstall build-essential apt-utils && chmod +x /entrypoint.sh && add-apt-repository -y ppa:ondrej/php && apt update && apt -y dist-upgrade && apt-get install -y nginx php7.3-fpm php7.3-common php7.3-mysql php7.3-gmp php7.3-curl php7.3-intl php7.3-mbstring php7.3-xmlrpc php7.3-gd php7.3-xml php7.3-cli php7.3-zip php7.3-soap php7.3-imap nano

COPY setup/nginx.conf /etc/nginx/nginx.conf
COPY setup/php.ini /etc/php/7.3/fpm/php.ini
COPY setup/default /etc/nginx/sites-available/default
COPY setup/www.conf /etc/php/7.3/fpm/pool.d/www.conf

# RStudio server:
RUN apt-get install -y libclang-dev && wget https://www.rstudio.org/download/latest/stable/server/bionic/rstudio-server-latest-amd64.deb && dpkg -i rstudio-server-latest-amd64.deb && apt -f -y install && cd / && rm rstudio-server-latest-amd64.deb 

# MXNET:
# RUN apt-get install -y libopencv-dev && Rscript -e "install.packages('opencv')" && pip install --upgrade cmake && cd / && git clone --recursive https://github.com/apache/incubator-mxnet.git -b v1.x && cd /incubator-mxnet && mkdir build && cd build && cmake -DUSE_CUDA=OFF -DUSE_MKL_IF_AVAILABLE=ON -DUSE_MKLDNN=OFF -DUSE_OPENMP=ON -DUSE_OPENCV=ON .. && make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas && make install && cp -a . .. && cp -a . ../lib && cd /incubator-mxnet/ && make -f R-package/Makefile rpkg

# Shiny server:
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && VERSION=$(cat version.txt)  && wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && gdebi -n ss-latest.deb && rm -f version.txt ss-latest.deb
COPY setup/shiny-server.conf /etc/shiny-server/shiny-server.conf 
RUN Rscript -e 'install.packages(c("shiny","rmarkdown","shinydashboard"))'

ADD modules /home/app/modules/
COPY setup/index.php /home/app/www/index.php

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]