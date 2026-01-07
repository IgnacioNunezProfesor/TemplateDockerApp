# Imagen base ligera basada en Alpine Linux
FROM alpine:latest

# Variables de entorno configurables en tiempo de construcción (build)
# Se usan para parametrizar la configuración de MariaDB
ARG DB_PORT=${DB_PORT} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_DATADIR=${DB_DATADIR} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Variables de entorno disponibles en tiempo de ejecución del contenedor
# Se reutilizan los valores definidos durante el build
ENV DB_PORT=${DB_PORT} \
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Instalación de MariaDB, cliente y utilidades necesarias
# Se crea el usuario del sistema, directorios necesarios y se asignan permisos
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \
    addgroup -S ${DB_USER} && \
    adduser -S ${DB_USER} -G ${DB_USER} && \
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}

# Copia el script de entrada (entrypoint) al contenedor
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh

# Copia los scripts SQL que se ejecutarán al iniciar el contenedor
COPY ./docker/bd/sql/*.sql /entrypointsql/

# Copia el archivo de configuración personalizada de MySQL
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf

# Asigna permisos y propietario al entrypoint y muestra su contenido
RUN chown -R ${DB_USER}:${DB_USER} /entrypoint* && \
    chmod 755 /entrypoint.sh && \
    ls -la /entrypoint*

# Convierte el archivo a formato Unix y asegura permisos de ejecución
RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh

# Ejecutar el contenedor con el usuario de base de datos (comentado por compatibilidad)
#USER ${DB_USER}

# Expone el puerto configurado para MariaDB
EXPOSE ${DB_PORT}

# Define el script de entrada que se ejecuta al iniciar el contenedor
ENTRYPOINT ["sh", "/entrypoint.sh" ]

