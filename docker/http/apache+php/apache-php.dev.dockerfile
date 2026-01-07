FROM alpine:latest 
# Imagen base ligera

ARG MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT} 
# Puerto del servidor Moodle (build-time)
ARG MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME} 
# Nombre del servidor Moodle (build-time)

ENV MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT} 
# Exporta el puerto al entorno del contenedor
ENV MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME} 
# Exporta el nombre del servidor al entorno

EXPOSE ${MOODLE_SERVER_PORT} 
# Expone el puerto HTTP configurado
EXPOSE 9003 
# Puerto usado por Xdebug

RUN apk update && apk upgrade && \ 
# Actualiza repos y paquetes
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \ 
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \ 
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug 
    # # Instala Apache, PHP y Extensiones necesarias para Moodle

RUN mkdir -p /var/www/${MOODLE_SERVER_PORT} \ 
# Crea el directorio del VirtualHost
    && chown -R apache:apache /var/www/${MOODLE_SERVER_PORT} \ 
    # Asigna permisos al usuario Apache
    && chmod -R 755 /var/www/${MOODLE_SERVER_PORT} 
    # Permisos de lectura/ejecución

COPY ./docker/http/apache+php/conf/httpd.conf /etc/apache2/httpd.conf 
# Copia la config principal de Apache
COPY ./docker/http/apache+php/conf.d/php-xdebug.ini /etc/php84/conf.d/php-xdebug.ini 
# Configuración de Xdebug
COPY ./docker/http/apache+php/conf.d/*.conf /etc/apache2/conf.d/ 
# Copia configs adicionales (VirtualHost, módulos, etc.)

ENTRYPOINT ["httpd", "-D", "FOREGROUND"] 
# Inicia Apache en primer plano
