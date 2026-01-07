# Imagen base ligera basada en Alpine Linux
FROM alpine:latest

# Variables de construcción (build-time) configurables para el contenedor
ARG MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT}
ARG MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME}

# Variables de entorno disponibles en tiempo de ejecución
ENV MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT}
ENV MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME}

# Expone los puertos para Apache y Xdebug
EXPOSE ${MOODLE_SERVER_PORT}   # Puerto donde se servirá Moodle
EXPOSE 9003                   # Puerto usado por Xdebug para depuración

# Instala Apache, PHP y todas las extensiones necesarias para Moodle
RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug

# Crea el directorio donde se servirá Moodle y asigna permisos
RUN mkdir -p /var/www/${MOODLE_SERVER_PORT} \
    && chown -R apache:apache /var/www/${MOODLE_SERVER_PORT} \
    && chmod -R 755 /var/www/${MOODLE_SERVER_PORT}

# Copia el archivo principal de configuración de Apache al contenedor
COPY ./docker/http/apache+php/conf/httpd.conf /etc/apache2/httpd.conf

# Copia la configuración de Xdebug para PHP
COPY ./docker/http/apache+php/conf.d/php-xdebug.ini /etc/php84/conf.d/php-xdebug.ini

# Copia configuraciones adicionales de Apache
COPY ./docker/http/apache+php/conf.d/*.conf /etc/apache2/conf.d/

# Define el comando que se ejecuta al iniciar el contenedor
# Ejecuta Apache en primer plano para mantener el contenedor activo
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]
