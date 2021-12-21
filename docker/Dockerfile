FROM artifactory.wma.chs.usgs.gov/docker-official-mirror/rocker/r-ver:4.0.4

ARG BUILD_DATE

LABEL maintainer="wwatkins@usgs.gov"
LABEL version=0.0.2
LABEL org.label-schema.build-date=$BUILD_DATE

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    apt-utils \
    wget \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev

#bring in DOI root cert.  Remove this statement for non-USGS persons
RUN /usr/bin/wget -O /usr/lib/ssl/certs/DOIRootCA.crt http://sslhelp.doi.net/docs/DOIRootCA2.cer && \
  ln -sf /usr/lib/ssl/certs/DOIRootCA.crt /usr/lib/ssl/certs/`openssl x509 -hash -noout -in /usr/lib/ssl/certs/DOIRootCA.crt`.0 && \
  echo "\\n\\nca-certificate = /usr/lib/ssl/certs/DOIRootCA.crt" >> /etc/wgetrc;
  
  RUN install2.r --error \
  httr \
  googleAuthR \
  googleAnalyticsR \
  dplyr \
  tidyr \
  arrow \
  lubridate \
  yaml \
  dataRetrieval \
  ineq \
  plyr

RUN Rscript -e 'arrow::install_arrow()' #installs some runtime libraries 

#once slow_fetch fix is on CRAN, can remove remotes and googleAnalyticsR github install
RUN Rscript -e 'install.packages("remotes"); remotes::install_github("https://github.com/MarkEdmondson1234/googleAnalyticsR")' 

RUN mkdir -p /home/analytics_pipeline
WORKDIR /home/analytics_pipeline
CMD ["/init"]

