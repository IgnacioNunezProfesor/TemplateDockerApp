# Dockerfile for Apache with PHP for development environment
# Install Apache and PHP
# Copy custom Apache configuration for development
# Set working directory to the document root
# Expose port 80 for HTTP traffic
# Start Apache in the foreground
# Use environment variable for document root
# Use Alpine Linux for a lightweight image
# Install necessary packages without cache
# Update package list
# Create the document root directory
# Set maintainer and description labels
# Use environment variable for document root
# Use Alpine Linux for a lightweight image

FROM alpine:latest
LABEL maintainer="Coder Nacho"
LABEL description="Dockerfile for Apache with PHP for development environment"
ENV APACHE_DOCUMENT_ROOT=$[APACHE_DOCUMENT_ROOT]
ARG APACHE_DOCUMENT_ROOT
RUN apk update && apk upgrade && \
    apk add --no-cache apache2 php php-apache2 
RUN apk add php82-gd php82-mbstring php82-intl php82-mysqli php82-xml php82-zip \
        php82-ctype php82-dom php82-iconv php82-json php82-pcre php82-simplexml php82-spl \
        php82-openssl php82-sodium php82-tokenizer php82-xmlrpc && \
    mkdir -p ${APACHE_DOCUMENT_ROOT}
COPY ./docker/apache+php/config/000-default.dev.conf /etc/apache2/conf.d/000-default.conf
WORKDIR ${APACHE_DOCUMENT_ROOT}
EXPOSE 80
CMD ["httpd", "-D", "FOREGROUND"]