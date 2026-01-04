# Imagen base ligera para construir Apache + PHP
FROM alpine:latest

# Variables de construcción (solo disponibles durante el build)
ARG SERVER_PORT=${SERVER_PORT}
ARG SERVER_NAME=${SERVER_NAME}
ARG FOLDER_NAME=${FOLDER_NAME}

# Variables de entorno disponibles dentro del contenedor en ejecución
ENV FOLDER_NAME=${FOLDER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_NAME=${SERVER_NAME}

# Expone el puerto del servidor Apache
EXPOSE ${SERVER_PORT}
# Expone el puerto de Xdebug (9003)
EXPOSE 9003

# Actualiza paquetes e instalar Apache + PHP + extensiones necesarias
RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug

# Crea carpeta del proyecto, asignar permisos y preparar directorio de configuración PHP
RUN mkdir -p ${FOLDER_NAME} \
    && chown -R apache:apache ${FOLDER_NAME} \
    && chmod -R 755 ${FOLDER_NAME} \
    && mkdir -p /etc/php84/conf.d

# Copia configuración de Apache
COPY ./docker/http/apache+php/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/http/apache+php/apache/conf.d/*.conf /etc/apache2/conf.d/
# Copia configuración de PHP y módulos adicionales
COPY ./docker/http/apache+php/php/php.ini /etc/php84/
COPY ./docker/http/apache+php/php/conf.d/*.ini /etc/php84/conf.d/

# Ejecuta Apache en primer plano (necesario para Docker)
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]
