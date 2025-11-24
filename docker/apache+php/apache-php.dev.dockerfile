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
ENV APACHE_DOCUMENT_ROOT $[APACHE_DOCUMENT_ROOT]
ARG APACHE_DOCUMENT_ROOT
RUN apk update && \
    apk add --no-cache apache2 php php-apache2 && \
    mkdir -p ${APACHE_DOCUMENT_ROOT}
COPY ./docker/apache+php/config/000-default.dev.conf /etc/apache2/conf.d/000-default.conf
COPY ../../src/* ${APACHE_DOCUMENT_ROOT}/
WORKDIR ${APACHE_DOCUMENT_ROOT}
EXPOSE 80
CMD ["httpd", "-D", "FOREGROUND"]