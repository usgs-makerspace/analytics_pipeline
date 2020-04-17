FROM rocker/r-ver:3.6.3

ARG BUILD_DATE

LABEL maintainer="wwatkins@usgs.gov"
LABEL version=0.0.1
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
  arrow \
  lubridate \
  yaml \
  dataRetrieval

RUN Rscript -e 'arrow::install_arrow()' #installs some runtime libraries

RUN mkdir -p /home/analytics_pipeline
WORKDIR wbeep-processing
CMD ["/init"]

