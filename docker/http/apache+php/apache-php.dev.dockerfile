FROM alpine:latest

ARG SERVER_PORT=${SERVER_PORT}
ARG SERVER_NAME=${SERVER_NAME}
ARG FOLDER_NAME=${FOLDER_NAME}
ARG DATA_FOLDER=${DATA_FOLDER}

ENV FOLDER_NAME=${FOLDER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_NAME=${SERVER_NAME}
ENV DATA_FOLDER=${DATA_FOLDER}

EXPOSE ${SERVER_PORT}
EXPOSE 9003

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug

RUN mkdir -p ${FOLDER_NAME} \
    && chown -R apache:apache ${FOLDER_NAME} \
    && chmod -R 755 ${FOLDER_NAME} \
    && mkdir -p /etc/php84/conf.d \
    && mkdir -p ${DATA_FOLDER} \
    && chown -R apache:apache ${DATA_FOLDER} \
    && chmod -R 755 ${DATA_FOLDER}

COPY ./docker/http/apache+php/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/http/apache+php/apache/conf.d/*.conf /etc/apache2/conf.d/
COPY ./docker/http/apache+php/php/php.ini /etc/php84/
COPY ./docker/http/apache+php/php/conf.d/*.ini /etc/php84/conf.d/

ENTRYPOINT ["httpd", "-D", "FOREGROUND"]