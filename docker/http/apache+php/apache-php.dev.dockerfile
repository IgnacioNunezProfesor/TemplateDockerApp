# Usa la última versión de Alpine Linux como base
FROM alpine:latest

# Define una variable de argumento para el puerto del servidor Moodle
ARG MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT}
# Define una variable de argumento para el nombre del servidor Moodle
ARG MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME}

# Establece la variable de entorno del puerto
ENV MOODLE_SERVER_PORT=${MOODLE_SERVER_PORT}
# Establece la variable de entorno del nombre del servidor
ENV MOODLE_SERVER_NAME=${MOODLE_SERVER_NAME}

# Abre el puerto del servidor Moodle para acceso externo
EXPOSE ${MOODLE_SERVER_PORT}
# Abre el puerto 9003 (usado por Xdebug)
EXPOSE 9003
# Linea 1: Actualiza los paquetes del sistema
# Linea 2: Instala Apache y PHP
# Linea 3: Instala extensiones necesarias para Moodle
# Linea 4: Más extensiones + Xdebug
RUN apk update && apk upgrade && \ 
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug
# Linea 1: Crea la carpeta donde irá el sitio Moodle
# Linea 2: Asigna permisos al usuario Apache
# Linea 3: Da permisos de lectura y ejecución
    RUN mkdir -p /var/www/${MOODLE_SERVER_PORT} \
    && chown -R apache:apache /var/www/${MOODLE_SERVER_PORT} \
    && chmod -R 755 /var/www/${MOODLE_SERVER_PORT}

# Copia el archivo principal de configuración de Apache
COPY ./docker/http/apache+php/conf/httpd.conf /etc/apache2/httpd.conf
# Copia la configuración de Xdebug
COPY ./docker/http/apache+php/conf.d/php-xdebug.ini /etc/php84/conf.d/php-xdebug.ini
# Copia todos los archivos de configuración extra de Apache
COPY ./docker/http/apache+php/conf.d/*.conf /etc/apache2/conf.d/
# Inicia Apache en primer plano
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]