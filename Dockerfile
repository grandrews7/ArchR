FROM rocker/tidyverse:4.1

USER root
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ="America/New_York"

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    wget \
    #For ArchR
    libbz2-dev \
    #For IRkernel
    libzmq3-dev \
    #For Seurat
    libglpk-dev

RUN R -e "options(warn=2); install.packages('BiocManager')"

RUN wget http://gnu.mirror.constant.com/gsl/gsl-2.6.tar.gz && \
    tar -xzvf gsl-2.6.tar.gz && \
    cd gsl-2.6 && \
    ./configure && \
    make && \
    make install && \
    cd

RUN R -e 'options(warn=2); ld_path <- paste(Sys.getenv("LD_LIBRARY_PATH"), "/usr/local/lib/", sep = ";"); Sys.setenv(LD_LIBRARY_PATH = ld_path); devtools::install_github("GreenleafLab/ArchR", ref="dev", repos = BiocManager::repositories())'

RUN R -e 'options(warn=2); library(ArchR); ArchR::installExtraPackages()'

RUN R -e 'options(warn=2); BiocManager::install(c("BSgenome.Hsapiens.UCSC.hg19", "BSgenome.Hsapiens.UCSC.hg38", "JASPAR2020"))'

RUN R -e 'options(warn=2); ld_path <- paste(Sys.getenv("LD_LIBRARY_PATH"), "/usr/local/lib/", sep = ";"); Sys.setenv(LD_LIBRARY_PATH = ld_path); BiocManager::install(c("DirichletMultinomial", "chromVAR", "motifmatchr"), force=TRUE)'

RUN R -e 'options(warn=2); ld_path <- paste(Sys.getenv("LD_LIBRARY_PATH"), "/usr/local/lib/", sep = ";"); Sys.setenv(LD_LIBRARY_PATH = ld_path); devtools::install_github("GreenleafLab/chromVARmotifs")'

RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/" >> ~/.bashrc
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

ARG PYTHON_VERSION=3.9.17

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xvf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make && make install && \
    cd .. && rm Python-${PYTHON_VERSION}.tgz && rm -r Python-${PYTHON_VERSION} && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
    python -m pip install --upgrade pip && \
    rm -r /root/.cache/pip

RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
    	jupyterlab MACS2

# R jupyter kernel
RUN R -e "options(warn=2); install.packages('IRkernel'); IRkernel::installspec(user=F)"

# Extra R packages
RUN R -e "options(warn=2); install.packages(c('hexbin', 'pheatmap'))"

CMD ["/bin/bash"]